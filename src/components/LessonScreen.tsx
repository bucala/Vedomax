import React, { useState, useEffect, useRef, useCallback } from 'react';
import { Lesson, GamePhase, GameState } from '../types';
import { LearningRepository } from '../services/learningRepository';
import { PuzzleCalc } from './mechanics/PuzzleCalc';
import { DetectiveMode } from './mechanics/DetectiveMode';
import { GeoClick } from './mechanics/GeoClick';
import { SuccessAnimation } from './SuccessAnimation';
import { ArrowLeft, RotateCcw, AlertTriangle, Loader2 } from 'lucide-react';

interface LessonScreenProps {
  lesson: Lesson;
  repository: LearningRepository;
  isDemo: boolean;
  onBack: () => void;
  onSyncProfile?: () => void;
}

export const LessonScreen: React.FC<LessonScreenProps> = ({
  lesson,
  repository,
  isDemo,
  onBack,
  onSyncProfile,
}) => {
  const [state, setState] = useState<GameState>({
    phase: 'loading',
    index: 0,
    remaining: lesson.seconds,
    score: 0,
    xp: 0,
    animationTrigger: 0,
  });

  const answersRef = useRef<Record<string, any>>({});
  const deadlineRef = useRef<Date | null>(null);
  const timerRef = useRef<any>(null);

  const startLesson = useCallback(async () => {
    setState({
      phase: 'loading',
      index: 0,
      remaining: lesson.seconds,
      score: 0,
      xp: 0,
      animationTrigger: 0,
    });
    answersRef.current = {};

    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }

    try {
      if (!lesson.questions || lesson.questions.length === 0) {
        throw new Error('Empty lesson');
      }
      const deadline = await repository.begin(lesson.id);
      deadlineRef.current = deadline;

      const updateRemaining = () => {
        if (!deadlineRef.current) return;
        const diffMs = deadlineRef.current.getTime() - Date.now();
        const rem = Math.max(0, Math.min(Math.ceil(diffMs / 1000), lesson.seconds));
        if (rem <= 0) {
          if (timerRef.current) {
            clearInterval(timerRef.current);
            timerRef.current = null;
          }
          setState((prev) => ({
            ...prev,
            phase: 'error',
            remaining: 0,
            message: 'Čas vypršal. Skús lekciu ešte raz.',
          }));
        } else {
          setState((prev) => {
            if (prev.phase === 'submitting' || prev.phase === 'finished' || prev.phase === 'error') {
              return prev;
            }
            return {
              ...prev,
              phase: 'playing',
              remaining: rem,
            };
          });
        }
      };

      updateRemaining();
      timerRef.current = setInterval(updateRemaining, 250);
    } catch {
      setState({
        phase: 'error',
        index: 0,
        remaining: 0,
        score: 0,
        xp: 0,
        animationTrigger: 0,
        message: 'Lekciu sa nepodarilo spustiť. Skontroluj pripojenie a skús znova.',
      });
    }
  }, [lesson, repository]);

  useEffect(() => {
    startLesson();
    return () => {
      if (timerRef.current) {
        clearInterval(timerRef.current);
      }
    };
  }, [startLesson]);

  const handleAnswer = async (answer: any) => {
    if (state.phase !== 'playing' || state.remaining === 0) return;

    const currentQuestion = lesson.questions[state.index];
    answersRef.current[currentQuestion.id] = answer;

    if (state.index + 1 < lesson.questions.length) {
      setState((prev) => ({
        ...prev,
        index: prev.index + 1,
      }));
      return;
    }

    // Finished all questions -> submit
    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }

    setState((prev) => ({ ...prev, phase: 'submitting' }));

    try {
      const result = await repository.submit(lesson.id, answersRef.current);
      if (onSyncProfile) {
        onSyncProfile();
      }
      setState({
        phase: 'finished',
        index: state.index,
        remaining: state.remaining,
        score: result.score,
        xp: result.xp,
        animationTrigger: result.score === 100 ? 1 : 0,
      });
    } catch {
      setState({
        phase: 'error',
        index: state.index,
        remaining: 0,
        score: 0,
        xp: 0,
        animationTrigger: 0,
        message: 'Výsledok sa nepotvrdil. Skontroluj pripojenie a reštartuj lekciu.',
      });
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-zinc-950 flex flex-col">
      {/* App Bar */}
      <header className="sticky top-0 z-20 backdrop-blur-md bg-white/80 dark:bg-zinc-900/80 border-b border-slate-200 dark:border-zinc-800 px-4 py-3 sm:px-6">
        <div className="max-w-3xl mx-auto flex items-center justify-between">
          <button
            type="button"
            onClick={onBack}
            className="flex items-center gap-2 text-slate-700 dark:text-zinc-300 hover:text-slate-900 dark:hover:text-white font-medium transition-colors cursor-pointer"
          >
            <ArrowLeft className="w-5 h-5" />
            <span className="hidden sm:inline">Späť na predmety</span>
          </button>
          <h1 className="text-base sm:text-lg font-bold text-slate-900 dark:text-zinc-100 truncate px-2">
            {lesson.title}
          </h1>
          <div className="w-16 flex justify-end">
            {state.phase === 'playing' && (
              <span className="px-2.5 py-1 rounded-full text-xs font-semibold bg-purple-100 dark:bg-purple-900/40 text-[#6750a4] dark:text-[#a6e55c]">
                {state.remaining}s
              </span>
            )}
          </div>
        </div>
      </header>

      {/* Main Body */}
      <main className="flex-1 flex flex-col items-center justify-center p-4 sm:p-6 md:p-8">
        <div className="w-full max-w-xl mx-auto">
          {state.phase === 'loading' && (
            <div className="flex flex-col items-center justify-center py-20 space-y-4">
              <Loader2 className="w-10 h-10 animate-spin text-[#6750a4] dark:text-[#a6e55c]" />
              <p className="text-sm text-slate-500 dark:text-zinc-400">Načítavam lekciu…</p>
            </div>
          )}

          {state.phase === 'submitting' && (
            <div className="flex flex-col items-center justify-center py-20 space-y-4">
              <Loader2 className="w-10 h-10 animate-spin text-[#6750a4] dark:text-[#a6e55c]" />
              <p className="text-sm text-slate-500 dark:text-zinc-400">Overujem odpovede…</p>
            </div>
          )}

          {state.phase === 'error' && (
            <div className="bg-white dark:bg-zinc-900 rounded-3xl p-8 border border-red-200 dark:border-red-900/50 shadow-sm text-center space-y-6">
              <div className="w-14 h-14 mx-auto rounded-full bg-red-100 dark:bg-red-950/60 flex items-center justify-center text-red-600 dark:text-red-400">
                <AlertTriangle className="w-7 h-7" />
              </div>
              <p className="text-base font-medium text-slate-800 dark:text-zinc-200">
                {state.message}
              </p>
              <div className="flex flex-col sm:flex-row gap-3 justify-center">
                <button
                  type="button"
                  onClick={startLesson}
                  className="flex items-center justify-center gap-2 py-3 px-6 rounded-xl font-medium bg-[#6750a4] hover:bg-[#563f8f] dark:bg-[#a6e55c] dark:hover:bg-[#94d548] text-white dark:text-[#1c3600] shadow-sm transition-colors cursor-pointer"
                >
                  <RotateCcw className="w-4 h-4" />
                  <span>Skúsiť znova</span>
                </button>
                <button
                  type="button"
                  onClick={onBack}
                  className="py-3 px-6 rounded-xl font-medium text-slate-600 dark:text-zinc-400 hover:bg-slate-100 dark:hover:bg-zinc-800 transition-colors cursor-pointer"
                >
                  Späť na predmety
                </button>
              </div>
            </div>
          )}

          {state.phase === 'finished' && (
            <div className="bg-white dark:bg-zinc-900 rounded-3xl p-8 border border-slate-200 dark:border-zinc-800 shadow-sm text-center flex flex-col items-center space-y-6 animate-fade-in">
              {state.animationTrigger > 0 ? (
                <SuccessAnimation animationPath={lesson.animation} />
              ) : (
                <div className="w-24 h-24 rounded-full bg-amber-100 dark:bg-amber-950/40 flex items-center justify-center text-amber-600 dark:text-amber-400">
                  <RotateCcw className="w-10 h-10" />
                </div>
              )}

              <div className="space-y-2">
                <h2 className="text-2xl font-bold text-slate-900 dark:text-zinc-100">
                  {state.score === 100 ? 'Výborne! Misia splnená.' : 'Ešte kúsok tréningu!'}
                </h2>
                <p className="text-base text-slate-600 dark:text-zinc-400 font-medium">
                  Skóre: <span className="font-bold text-slate-900 dark:text-zinc-100">{state.score} %</span> • +
                  <span className="font-bold text-[#6750a4] dark:text-[#a6e55c]">{state.xp} XP</span>
                  {isDemo ? ' (demo)' : ''}
                </p>
              </div>

              <div className="w-full flex flex-col sm:flex-row gap-3 pt-4">
                <button
                  type="button"
                  onClick={startLesson}
                  className="flex-1 py-3 px-6 rounded-xl font-medium bg-[#6750a4] hover:bg-[#563f8f] dark:bg-[#a6e55c] dark:hover:bg-[#94d548] text-white dark:text-[#1c3600] shadow-sm transition-colors cursor-pointer"
                >
                  Zopakovať
                </button>
                <button
                  type="button"
                  onClick={onBack}
                  className="flex-1 py-3 px-6 rounded-xl font-medium text-slate-700 dark:text-zinc-300 hover:bg-slate-100 dark:hover:bg-zinc-800 transition-colors cursor-pointer"
                >
                  Späť na predmety
                </button>
              </div>
            </div>
          )}

          {state.phase === 'playing' && (
            <div className="bg-white dark:bg-zinc-900 rounded-3xl p-6 sm:p-8 border border-slate-200 dark:border-zinc-800 shadow-sm space-y-6">
              {/* Progress and countdown */}
              <div className="space-y-2">
                <div className="flex items-center justify-between text-xs font-semibold text-slate-500 dark:text-zinc-400 uppercase tracking-wider">
                  <span>
                    Otázka {state.index + 1}/{lesson.questions.length}
                  </span>
                  <span>{state.remaining} s</span>
                </div>
                <div className="w-full h-2 rounded-full bg-slate-100 dark:bg-zinc-800 overflow-hidden">
                  <div
                    className="h-full bg-[#6750a4] dark:bg-[#a6e55c] transition-all duration-300"
                    style={{
                      width: `${(state.remaining / lesson.seconds) * 100}%`,
                    }}
                  />
                </div>
              </div>

              {/* Question text */}
              <h3 className="text-xl sm:text-2xl font-bold text-slate-900 dark:text-zinc-100">
                {lesson.questions[state.index].text}
              </h3>

              {/* Mechanic widget */}
              <div className="pt-2">
                {lesson.questions[state.index].mechanic === 'puzzle_calc' && (
                  <PuzzleCalc
                    key={lesson.questions[state.index].id}
                    question={lesson.questions[state.index]}
                    onAnswer={handleAnswer}
                  />
                )}
                {lesson.questions[state.index].mechanic === 'detective' && (
                  <DetectiveMode
                    key={lesson.questions[state.index].id}
                    question={lesson.questions[state.index]}
                    onAnswer={handleAnswer}
                  />
                )}
                {lesson.questions[state.index].mechanic === 'geo_click' && (
                  <GeoClick
                    key={lesson.questions[state.index].id}
                    question={lesson.questions[state.index]}
                    onAnswer={handleAnswer}
                  />
                )}
                {!['puzzle_calc', 'detective', 'geo_click'].includes(
                  lesson.questions[state.index].mechanic
                ) && (
                  <div className="p-8 text-center text-slate-500 dark:text-zinc-400">
                    Táto mechanika bude dostupná v ďalšej verzii.
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </main>
    </div>
  );
};
