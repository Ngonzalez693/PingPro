/**
 * npm run avatars:cleanup-orphans
 *
 * Se lanza a mano (por ejemplo tras una caída de Supabase) con las variables
 * de producción: borra las carpetas de fotos de usuarios que ya no existen.
 */
import { createPool } from '../config/postgres';
import { PostgresUserRepository } from '../repositories/implementations/PostgresUserRepository';
import { cleanupOrphanAvatars } from '../services/storage/cleanupOrphanAvatars';
import { SupabaseAvatarStorage, createAvatarStorage } from '../services/storage/SupabaseAvatarStorage';

async function main(): Promise<void> {
  const storage = createAvatarStorage(process.env);
  if (!(storage instanceof SupabaseAvatarStorage)) {
    console.error('Faltan SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY');
    process.exitCode = 1;
    return;
  }
  const pool = createPool();
  try {
    const cleaned = await cleanupOrphanAvatars(storage, new PostgresUserRepository(pool));
    console.log(cleaned.length > 0 ? `Borradas: ${cleaned.join(', ')}` : 'No había fotos huérfanas');
  } finally {
    await pool.end();
  }
}

main().catch((err: unknown) => {
  console.error(err);
  process.exitCode = 1;
});
