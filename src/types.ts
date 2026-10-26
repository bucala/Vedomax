export type MechanicType = 'puzzle_calc' | 'detective' | 'geo_click' | 'rpg_chat' | 'drag_drop';

export interface Question {
  id: string;
  text: string;
  mechanic: MechanicType;
  content: Record<string, any>;
}

export interface Lesson {
  id: number;
  title: string;
  seconds: number;
  questions: Question[];
  animation?: string;
}

export interface LessonResult {
  score: number;
  xp: number;
  correct?: number;
  total?: number;
}

export interface Profile {
  id: string;
  username: string;
  xp: number;
  streak: number;
  lastActiveAt?: string;
  leaderboardVisible?: boolean;
}

export interface LeaderboardEntry {
  username: string;
  xp: number;
}

export type GamePhase = 'loading' | 'playing' | 'submitting' | 'finished' | 'error';

export interface GameState {
  phase: GamePhase;
  index: number;
  remaining: number;
  score: number;
  xp: number;
  animationTrigger: number;
  message?: string;
}
