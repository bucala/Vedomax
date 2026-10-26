import React, { useState, useEffect, useCallback } from 'react';
import { Lesson, Profile, LeaderboardEntry } from '../types';
import { LearningRepository, ProfileRepository } from '../services/learningRepository';
import { AuthUser } from '../services/authService';
import {
  Zap,
  ChevronRight,
  LogOut,
  Moon,
  Sun,
  Trophy,
  Flame,
  User,
  ShieldAlert,
  Edit2,
  Check,
  Eye,
  EyeOff,
  Sparkles,
} from 'lucide-react';

interface DashboardProps {
  lessons: Lesson[];
  repository: LearningRepository;
  profileRepo?: ProfileRepository;
  currentUser: AuthUser | null;
  isDemo: boolean;
  onSelectLesson: (lesson: Lesson) => void;
  onSignOut: () => void;
  onSwitchToAuth: () => void;
  onSwitchToDemo: () => void;
  isDark: boolean;
  onToggleTheme: () => void;
}

export const Dashboard: React.FC<DashboardProps> = ({
  lessons,
  repository: _repo,
  profileRepo,
  currentUser,
  isDemo,
  onSelectLesson,
  onSignOut,
  onSwitchToAuth,
  onSwitchToDemo,
  isDark,
  onToggleTheme,
}) => {
  const [profile, setProfile] = useState<Profile | null>(null);
  const [leaderboard, setLeaderboard] = useState<LeaderboardEntry[]>([]);
  const [showLeaderboard, setShowLeaderboard] = useState(false);
  const [editingUsername, setEditingUsername] = useState(false);
  const [newUsername, setNewUsername] = useState('');

  const loadProfileData = useCallback(async () => {
    if (currentUser && profileRepo) {
      const p = await profileRepo.load(currentUser.id);
      setProfile(p);
      if (p) {
        setNewUsername(p.username);
      }
      const lb = await profileRepo.getLeaderboard();
      setLeaderboard(lb);
    }
  }, [currentUser, profileRepo]);

  useEffect(() => {
    loadProfileData();
  }, [loadProfileData]);

  const handleSaveUsername = async () => {
    if (!currentUser || !profileRepo) return;
    const clean = newUsername.trim();
    if (clean.length < 3 || clean.length > 24) return;
    await profileRepo.updateUsername(currentUser.id, clean);
    setEditingUsername(false);
    loadProfileData();
  };

  const handleToggleLeaderboardOptIn = async () => {
    if (!currentUser || !profileRepo || !profile) return;
    const nextVal = !profile.leaderboardVisible;
    await profileRepo.toggleLeaderboard(currentUser.id, nextVal);
    loadProfileData();
  };

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-zinc-950 flex flex-col">
      {/* Top Navigation Bar */}
      <header className="sticky top-0 z-20 backdrop-blur-md bg-white/80 dark:bg-zinc-900/80 border-b border-slate-200 dark:border-zinc-800 px-4 py-3 sm:px-6">
        <div className="max-w-4xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-[#6750a4] dark:bg-[#a6e55c] flex items-center justify-center text-white dark:text-[#1c3600] font-black text-lg shadow-sm">
              V
            </div>
            <div>
              <span className="font-extrabold text-lg text-slate-900 dark:text-zinc-100">
                Vedomax
              </span>
              <span className="ml-2 inline-flex items-center px-2 py-0.5 rounded text-[11px] font-semibold bg-purple-100 dark:bg-purple-900/40 text-[#6750a4] dark:text-[#a6e55c]">
                {isDemo ? 'DEMO' : 'ÚČET'}
              </span>
            </div>
          </div>

          <div className="flex items-center gap-2">
            {/* Mode switch */}
            {isDemo ? (
              <button
                type="button"
                onClick={onSwitchToAuth}
                className="text-xs font-semibold px-3 py-1.5 rounded-lg border border-slate-200 dark:border-zinc-700 hover:bg-slate-100 dark:hover:bg-zinc-800 text-slate-700 dark:text-zinc-300 transition-colors cursor-pointer"
              >
                Prihlásiť sa
              </button>
            ) : (
              <button
                type="button"
                onClick={onSwitchToDemo}
                className="text-xs font-semibold px-3 py-1.5 rounded-lg border border-slate-200 dark:border-zinc-700 hover:bg-slate-100 dark:hover:bg-zinc-800 text-slate-700 dark:text-zinc-300 transition-colors cursor-pointer"
              >
                Prepnúť do Demo
              </button>
            )}

            {/* Leaderboard toggle */}
            <button
              type="button"
              onClick={() => setShowLeaderboard(!showLeaderboard)}
              title="Rebríček"
              className="p-2 rounded-xl text-slate-600 dark:text-zinc-300 hover:bg-slate-100 dark:hover:bg-zinc-800 transition-colors cursor-pointer"
            >
              <Trophy className="w-5 h-5 text-amber-500" />
            </button>

            {/* Dark/Light mode toggle */}
            <button
              type="button"
              onClick={onToggleTheme}
              title={isDark ? 'Svetlý režim' : 'Tmavý režim'}
              className="p-2 rounded-xl text-slate-600 dark:text-zinc-300 hover:bg-slate-100 dark:hover:bg-zinc-800 transition-colors cursor-pointer"
            >
              {isDark ? <Sun className="w-5 h-5 text-amber-400" /> : <Moon className="w-5 h-5" />}
            </button>

            {/* Sign Out (if auth) */}
            {!isDemo && currentUser && (
              <button
                type="button"
                onClick={onSignOut}
                title="Odhlásiť sa"
                className="p-2 rounded-xl text-slate-500 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/30 transition-colors cursor-pointer"
              >
                <LogOut className="w-5 h-5" />
              </button>
            )}
          </div>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="flex-1 flex justify-center p-4 sm:p-6 lg:p-8">
        <div className="w-full max-w-[700px] space-y-6">
          {/* Hero status banner */}
          <div className="bg-white dark:bg-zinc-900 rounded-3xl p-6 sm:p-8 border border-slate-200 dark:border-zinc-800 shadow-sm space-y-4">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <div>
                <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 dark:text-zinc-100 tracking-tight">
                  Tvoja ďalšia misia čaká
                </h2>
                <div className="mt-2 flex items-center gap-2">
                  {isDemo ? (
                    <span className="text-sm font-semibold text-purple-700 dark:text-[#a6e55c]">
                      DEMO • Bez účtu • XP sa neukladá
                    </span>
                  ) : (
                    <div className="flex flex-wrap items-center gap-3 text-sm font-semibold text-slate-700 dark:text-zinc-300">
                      <span className="flex items-center gap-1.5 bg-slate-100 dark:bg-zinc-800 px-3 py-1 rounded-full">
                        <User className="w-4 h-4 text-[#6750a4] dark:text-[#a6e55c]" />
                        {profile?.username || 'Hráč'}
                      </span>
                      <span className="flex items-center gap-1.5 bg-amber-50 dark:bg-amber-950/40 text-amber-800 dark:text-amber-300 px-3 py-1 rounded-full border border-amber-200 dark:border-amber-800/60">
                        <Sparkles className="w-4 h-4" />
                        {profile?.xp ?? 0} XP
                      </span>
                      <span className="flex items-center gap-1.5 bg-orange-50 dark:bg-orange-950/40 text-orange-800 dark:text-orange-300 px-3 py-1 rounded-full border border-orange-200 dark:border-orange-800/60">
                        <Flame className="w-4 h-4 text-orange-500" />
                        séria {profile?.streak ?? 1} dní
                      </span>
                    </div>
                  )}
                </div>
              </div>

              {!isDemo && profile && (
                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => setEditingUsername(!editingUsername)}
                    className="p-2 rounded-xl border border-slate-200 dark:border-zinc-700 hover:bg-slate-100 dark:hover:bg-zinc-800 text-slate-600 dark:text-zinc-400 text-xs font-medium inline-flex items-center gap-1.5 cursor-pointer"
                  >
                    <Edit2 className="w-3.5 h-3.5" />
                    <span>Zmeniť meno</span>
                  </button>
                </div>
              )}
            </div>

            {/* Username edit popup inline */}
            {!isDemo && editingUsername && (
              <div className="pt-3 border-t border-slate-100 dark:border-zinc-800 flex items-center gap-2">
                <input
                  type="text"
                  value={newUsername}
                  onChange={(e) => setNewUsername(e.target.value)}
                  maxLength={24}
                  placeholder="Nová prezývka (3-24 znakov)"
                  className="px-3 py-2 text-sm rounded-xl border border-slate-300 dark:border-zinc-700 bg-slate-50 dark:bg-zinc-950 text-slate-900 dark:text-zinc-100 focus:outline-none focus:ring-2 focus:ring-[#6750a4]"
                />
                <button
                  type="button"
                  onClick={handleSaveUsername}
                  className="p-2 bg-[#6750a4] text-white rounded-xl hover:bg-[#563f8f] cursor-pointer"
                >
                  <Check className="w-4 h-4" />
                </button>
                <button
                  type="button"
                  onClick={handleToggleLeaderboardOptIn}
                  className="text-xs text-slate-600 dark:text-zinc-400 hover:underline flex items-center gap-1 ml-auto cursor-pointer"
                >
                  {profile?.leaderboardVisible ? (
                    <>
                      <Eye className="w-3.5 h-3.5 text-emerald-600" />
                      <span>Viditeľný v rebríčku</span>
                    </>
                  ) : (
                    <>
                      <EyeOff className="w-3.5 h-3.5 text-slate-400" />
                      <span>Skrytý z rebríčka</span>
                    </>
                  )}
                </button>
              </div>
            )}

            <div className="pt-2 border-t border-slate-100 dark:border-zinc-800/80">
              <p className="text-xs text-slate-500 dark:text-zinc-400">
                Ukážkové učivo • overenie podľa iŠVP ešte prebieha
              </p>
            </div>
          </div>

          {/* Leaderboard drawer / card */}
          {showLeaderboard && (
            <div className="bg-white dark:bg-zinc-900 rounded-3xl p-6 border border-slate-200 dark:border-zinc-800 shadow-sm space-y-4 animate-fade-in">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Trophy className="w-5 h-5 text-amber-500" />
                  <h3 className="font-bold text-slate-900 dark:text-zinc-100">
                    Slovenský rebríček (Top 50)
                  </h3>
                </div>
                <span className="text-xs text-slate-400 dark:text-zinc-500">
                  Iba dobrovoľne zapojení žiaci
                </span>
              </div>

              <div className="divide-y divide-slate-100 dark:divide-zinc-800">
                {leaderboard.map((entry, idx) => (
                  <div
                    key={idx}
                    className="py-2.5 flex items-center justify-between text-sm"
                  >
                    <div className="flex items-center gap-3">
                      <span className="w-6 text-center font-bold text-slate-400 dark:text-zinc-500">
                        {idx + 1}.
                      </span>
                      <span className="font-medium text-slate-800 dark:text-zinc-200">
                        {entry.username}
                      </span>
                    </div>
                    <span className="font-semibold text-amber-600 dark:text-amber-400">
                      {entry.xp} XP
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Lessons List */}
          <div className="space-y-3">
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-zinc-400 px-1">
              Dostupné herné výzvy (8.–9. ročník)
            </h3>

            {lessons.map((lesson) => (
              <div
                key={lesson.id}
                onClick={() => onSelectLesson(lesson)}
                className="group p-5 bg-white dark:bg-zinc-900 hover:bg-purple-50/50 dark:hover:bg-zinc-800/60 rounded-3xl border border-slate-200 dark:border-zinc-800 hover:border-purple-200 dark:hover:border-zinc-700 shadow-sm transition-all duration-200 flex items-center justify-between cursor-pointer"
              >
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 rounded-2xl bg-purple-100 dark:bg-purple-950/60 flex items-center justify-center text-[#6750a4] dark:text-[#a6e55c] group-hover:scale-105 transition-transform">
                    <Zap className="w-6 h-6 fill-current" />
                  </div>
                  <div>
                    <h4 className="font-bold text-slate-900 dark:text-zinc-100 text-base sm:text-lg group-hover:text-[#6750a4] dark:group-hover:text-[#a6e55c] transition-colors">
                      {lesson.title}
                    </h4>
                    <p className="text-xs sm:text-sm text-slate-500 dark:text-zinc-400">
                      {lesson.seconds} sekúnd • herná výzva
                    </p>
                  </div>
                </div>

                <div className="flex items-center gap-2 text-slate-400 group-hover:text-[#6750a4] dark:group-hover:text-[#a6e55c] transition-colors">
                  <span className="hidden sm:inline text-xs font-semibold uppercase tracking-wider">
                    Spustiť
                  </span>
                  <ChevronRight className="w-5 h-5 group-hover:translate-x-0.5 transition-transform" />
                </div>
              </div>
            ))}
          </div>

          {/* Footer with safety & curriculum notices */}
          <div className="pt-6 text-center text-xs text-slate-400 dark:text-zinc-500 space-y-1">
            <p>Vedomax • Precvičovanie učiva hrou pre slovenské základné školy</p>
            <p>Pravidlá ochrany osobných údajov a bezpečnosť na internete</p>
          </div>
        </div>
      </main>
    </div>
  );
};
