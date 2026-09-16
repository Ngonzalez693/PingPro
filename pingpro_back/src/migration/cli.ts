/**
 * CLI de la migración: `npm run db:import-firestore`.
 *
 * Por defecto solo simula: lee Firestore, arma el plan y enseña el informe sin
 * escribir nada. --apply carga en la base de DATABASE_URL, --replace lo
 * permite aunque ya tenga datos, y --missing-users-only solo añade los
 * perfiles que falten (para después del corte).
 *
 * El informe solo nombra rutas e ids, nunca emails.
 */
import { createPool } from '../config/postgres';
import { insertMissingUsers, loadRows } from './load';
import { buildMigrationPlan, MigrationPlan, ProblemKind } from './plan';
import { readFirestoreSnapshot } from './readFirestore';

export interface CliOptions {
  apply: boolean;
  replace: boolean;
  missingUsersOnly: boolean;
}

const FLAGS: Record<string, keyof CliOptions> = {
  '--apply': 'apply',
  '--replace': 'replace',
  '--missing-users-only': 'missingUsersOnly',
};

const PROBLEM_ORDER: ProblemKind[] = ['blocking', 'discarded', 'warning'];

export function parseArgs(argv: string[]): CliOptions {
  const options: CliOptions = { apply: false, replace: false, missingUsersOnly: false };
  for (const arg of argv) {
    const option = FLAGS[arg];
    if (!option) {
      throw new Error(`Unknown option ${arg}. Valid options: ${Object.keys(FLAGS).join(', ')}`);
    }
    options[option] = true;
  }
  return options;
}

function printReport(plan: MigrationPlan): void {
  console.log('\nRows to migrate:');
  for (const [table, rows] of Object.entries(plan.rows)) {
    console.log(`  ${table.padEnd(22)} ${rows.length}`);
  }

  for (const kind of PROBLEM_ORDER) {
    const problems = plan.problems.filter((problem) => problem.kind === kind);
    if (problems.length === 0) {
      continue;
    }
    console.log(`\n${kind} (${problems.length}):`);
    for (const problem of problems) {
      console.log(`  ${problem.path}: ${problem.message}`);
    }
  }
}

async function write(plan: MigrationPlan, options: CliOptions): Promise<void> {
  const pool = createPool();
  const target = new URL(String(process.env.DATABASE_URL));
  console.log(`\nWriting to ${target.hostname}:${target.port}${target.pathname}`);
  try {
    if (options.missingUsersOnly) {
      const inserted = await insertMissingUsers(pool, plan.rows);
      console.log(`Inserted ${inserted} missing profiles`);
      return;
    }
    await loadRows(pool, plan.rows, { replace: options.replace });
    console.log('Migration applied');
  } finally {
    await pool.end();
  }
}

async function run(): Promise<void> {
  const options = parseArgs(process.argv.slice(2));
  const plan = buildMigrationPlan(await readFirestoreSnapshot(), new Date());
  printReport(plan);

  if (!options.apply && !options.missingUsersOnly) {
    console.log('\nDry run: nothing was written. Use --apply to migrate.');
    return;
  }

  const blocking = plan.problems.filter((problem) => problem.kind === 'blocking');
  if (blocking.length > 0) {
    throw new Error(`${blocking.length} blocking problems: fix them in Firestore or widen the rules`);
  }

  await write(plan, options);
}

if (require.main === module) {
  run().catch((err: unknown) => {
    console.error(err instanceof Error ? err.message : err);
    process.exitCode = 1;
  });
}
