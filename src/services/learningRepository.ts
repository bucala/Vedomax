import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { Lesson, LessonResult, Profile, LeaderboardEntry } from '../types';
import { DEMO_LESSONS } from '../data/lessons';

export interface LearningRepository {
  lessons(): Promise<Lesson[]>;
  begin(lessonId: number): Promise<Date>;
  submit(lessonId: number, answers: Record<string, any>): Promise<LessonResult>;
}

export interface ProfileRepository {
  load(userId: string): Promise<Profile | null>;
  updateUsername(userId: string, username: string): Promise<void>;
  toggleLeaderboard(userId: string, visible: boolean): Promise<void>;
  getLeaderboard(): Promise<LeaderboardEntry[]>;
}

export class DemoLearningRepository implements LearningRepository {
  async lessons(): Promise<Lesson[]> {
    return DEMO_LESSONS;
  }

  async begin(lessonId: number): Promise<Date> {
    const lesson = DEMO_LESSONS.find((l) => l.id === lessonId);
    const seconds = lesson ? lesson.seconds : 60;
    return new Date(Date.now() + seconds * 1000);
  }

  async submit(lessonId: number, answers: Record<string, any>): Promise<LessonResult> {
    let correct = false;
    switch (lessonId) {
      case 1: {
        const val = answers['math'];
        correct = typeof val === 'number' && Math.abs(val - 5) <= 0.01;
        break;
      }
      case 2: {
        const selected = Array.isArray(answers['detective']) ? [...answers['detective']].sort() : [];
        correct = selected.length === 2 && selected[0] === 1 && selected[1] === 5;
        break;
      }
      case 3: {
        const point = answers['geo'] as { x?: number; y?: number } | undefined;
        if (point && typeof point.x === 'number' && typeof point.y === 'number') {
          const dx = point.x - 0.307;
          const dy = point.y - 0.424;
          correct = dx * dx + dy * dy <= 0.0036; // 0.06^2
        }
        break;
      }
      default:
        correct = false;
    }

    // Demo never awards persistent XP
    return {
      score: correct ? 100 : 0,
      xp: 0,
    };
  }
}

// Local mock profile & progression store for authenticated mode when Supabase is not configured
const LOCAL_STORAGE_KEY_PROFILE = 'vedomax_local_profile';
const LOCAL_STORAGE_KEY_USERS = 'vedomax_local_users';
const LOCAL_STORAGE_KEY_LEADERBOARD = 'vedomax_local_leaderboard';

export class LocalLearningRepository implements LearningRepository {
  constructor(private userId: string) {}

  async lessons(): Promise<Lesson[]> {
    return DEMO_LESSONS;
  }

  async begin(lessonId: number): Promise<Date> {
    const lesson = DEMO_LESSONS.find((l) => l.id === lessonId);
    const seconds = lesson ? lesson.seconds : 60;
    return new Date(Date.now() + seconds * 1000);
  }

  async submit(lessonId: number, answers: Record<string, any>): Promise<LessonResult> {
    let correct = false;
    switch (lessonId) {
      case 1: {
        const val = answers['math'];
        correct = typeof val === 'number' && Math.abs(val - 5) <= 0.01;
        break;
      }
      case 2: {
        const selected = Array.isArray(answers['detective']) ? [...answers['detective']].sort() : [];
        correct = selected.length === 2 && selected[0] === 1 && selected[1] === 5;
        break;
      }
      case 3: {
        const point = answers['geo'] as { x?: number; y?: number } | undefined;
        if (point && typeof point.x === 'number' && typeof point.y === 'number') {
          const dx = point.x - 0.307;
          const dy = point.y - 0.424;
          correct = dx * dx + dy * dy <= 0.0036;
        }
        break;
      }
      default:
        correct = false;
    }

    const score = correct ? 100 : 0;
    // Calculate XP delta based on progression
    const progressionKey = `vedomax_prog_${this.userId}_${lessonId}`;
    const prevHighScore = parseInt(localStorage.getItem(progressionKey) || '0', 10);
    const xpDelta = Math.max(0, score - prevHighScore);
    if (score > prevHighScore) {
      localStorage.setItem(progressionKey, score.toString());
    }

    // Update profile
    const profileRaw = localStorage.getItem(`${LOCAL_STORAGE_KEY_PROFILE}_${this.userId}`);
    if (profileRaw) {
      const p: Profile = JSON.parse(profileRaw);
      p.xp += xpDelta;
      // Streak calculation (Bratislava local day)
      const now = new Date();
      const today = now.toISOString().split('T')[0];
      const lastActive = p.lastActiveAt ? p.lastActiveAt.split('T')[0] : null;

      if (lastActive === today) {
        // already active today
      } else {
        const yesterday = new Date(now.getTime() - 86400000).toISOString().split('T')[0];
        if (lastActive === yesterday) {
          p.streak += 1;
        } else {
          p.streak = 1;
        }
      }
      p.lastActiveAt = now.toISOString();
      localStorage.setItem(`${LOCAL_STORAGE_KEY_PROFILE}_${this.userId}`, JSON.stringify(p));
    }

    return {
      score,
      xp: xpDelta,
    };
  }
}

export class LocalProfileRepository implements ProfileRepository {
  async load(userId: string): Promise<Profile | null> {
    const raw = localStorage.getItem(`${LOCAL_STORAGE_KEY_PROFILE}_${userId}`);
    if (!raw) {
      const defaultProfile: Profile = {
        id: userId,
        username: 'Hrac_' + userId.replace(/[^a-zA-Z0-9]/g, '').slice(0, 12),
        xp: 0,
        streak: 1,
        leaderboardVisible: true,
      };
      localStorage.setItem(`${LOCAL_STORAGE_KEY_PROFILE}_${userId}`, JSON.stringify(defaultProfile));
      return defaultProfile;
    }
    return JSON.parse(raw);
  }

  async updateUsername(userId: string, username: string): Promise<void> {
    const profile = await this.load(userId);
    if (profile) {
      profile.username = username;
      localStorage.setItem(`${LOCAL_STORAGE_KEY_PROFILE}_${userId}`, JSON.stringify(profile));
    }
  }

  async toggleLeaderboard(userId: string, visible: boolean): Promise<void> {
    const profile = await this.load(userId);
    if (profile) {
      profile.leaderboardVisible = visible;
      localStorage.setItem(`${LOCAL_STORAGE_KEY_PROFILE}_${userId}`, JSON.stringify(profile));
    }
  }

  async getLeaderboard(): Promise<LeaderboardEntry[]> {
    const entries: LeaderboardEntry[] = [
      { username: 'Matus_Explorer', xp: 300 },
      { username: 'Sofi_Pytagoras', xp: 200 },
      { username: 'Lukas_Detektiv', xp: 150 },
    ];
    // Include all local users who opted in
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key && key.startsWith(LOCAL_STORAGE_KEY_PROFILE)) {
        try {
          const p: Profile = JSON.parse(localStorage.getItem(key) || '{}');
          if (p.leaderboardVisible && !entries.some((e) => e.username === p.username)) {
            entries.push({ username: p.username, xp: p.xp });
          }
        } catch {
          // ignore
        }
      }
    }
    return entries.sort((a, b) => b.xp - a.xp).slice(0, 50);
  }
}

// Supabase implementations if configured
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || '';
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY || '';

export const isSupabaseConfigured = Boolean(supabaseUrl && supabaseKey);
export const supabase: SupabaseClient | null = isSupabaseConfigured
  ? createClient(supabaseUrl, supabaseKey, {
      auth: {
        flowType: 'pkce',
        detectSessionInUrl: true,
      },
    })
  : null;

export class SupabaseLearningRepository implements LearningRepository {
  constructor(private client: SupabaseClient) {}

  async lessons(): Promise<Lesson[]> {
    const { data, error } = await this.client
      .from('lessons')
      .select('*,questions(*)')
      .order('id');
    if (error || !data) {
      return DEMO_LESSONS;
    }
    return data.map((row: any) => {
      const questions = (row.questions || []).sort(
        (a: any, b: any) => (a.order_index ?? 0) - (b.order_index ?? 0)
      );
      return {
        id: row.id,
        title: row.title_sk,
        seconds: row.time_limit_seconds,
        animation: row.lottie_asset_path || '/assets/animations/success.json',
        questions: questions.map((q: any) => ({
          id: q.id,
          text: q.question_text_sk,
          mechanic: q.mechanic_type,
          content: q.content_json,
        })),
      };
    });
  }

  async begin(lessonId: number): Promise<Date> {
    const { data, error } = await this.client.rpc('begin_lesson', { p_lesson_id: lessonId });
    if (error || !data) {
      throw new Error(error?.message || 'Failed to begin lesson');
    }
    return new Date(data);
  }

  async submit(lessonId: number, answers: Record<string, any>): Promise<LessonResult> {
    const { data, error } = await this.client.rpc('submit_lesson', {
      p_lesson_id: lessonId,
      p_answers: answers,
    });
    if (error || !data) {
      throw new Error(error?.message || 'Failed to submit lesson');
    }
    return {
      score: data.score,
      xp: data.xp_awarded,
      correct: data.correct,
      total: data.total,
    };
  }
}
