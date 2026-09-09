/**
 * Snapshot de actividad de un usuario (documento en users/{uid}/stats).
 *
 * Pensado como registro histórico agregado, pero hoy sin uso: la app arma sus
 * gráficas en el cliente a partir de los completedAt de ejercicios y
 * entrenamientos, sin pasar por /api/stats.
 */
export interface IUserStat {
  id?: string;
  userId: string;            
  exerciseCount: number;     
  trainingCount: number;    
  timestamp: Date;           
}
