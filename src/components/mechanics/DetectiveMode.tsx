import React, { useState } from 'react';
import { Question } from '../../types';
import { User, Check, X } from 'lucide-react';

interface DetectiveModeProps {
  question: Question;
  onAnswer: (indices: number[]) => void;
}

export const DetectiveMode: React.FC<DetectiveModeProps> = ({ question, onAnswer }) => {
  const [selected, setSelected] = useState<Set<number>>(new Set());

  const words: string[] = question.content.words || [
    'Moji',
    'kamarátiy',
    'dnes',
    'navštívili',
    'hrad.',
    'Bolily',
    'nadšení!',
  ];
  const errorIndices: Set<number> = new Set(
    question.content.error_indices || [1, 5]
  );

  const toggleWord = (index: number) => {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(index)) {
        next.delete(index);
      } else {
        next.add(index);
      }
      return next;
    });
  };

  const handleSubmit = () => {
    if (selected.size === 0) return;
    const sorted = Array.from(selected).sort((a, b) => a - b);
    onAnswer(sorted);
  };

  return (
    <div className="flex flex-col w-full max-w-xl mx-auto space-y-6">
      {/* School post card header */}
      <div className="flex items-center gap-3 p-4 rounded-2xl bg-purple-50 dark:bg-zinc-900 border border-purple-100 dark:border-zinc-800">
        <div className="w-10 h-10 rounded-full bg-[#6750a4]/10 dark:bg-[#a6e55c]/20 flex items-center justify-center text-[#6750a4] dark:text-[#a6e55c]">
          <User className="w-5 h-5" />
        </div>
        <div>
          <h4 className="font-semibold text-slate-900 dark:text-zinc-100 leading-tight">
            Školský príspevok
          </h4>
          <p className="text-xs text-slate-500 dark:text-zinc-400">
            Nájdi chyby • tréning pravopisu
          </p>
        </div>
      </div>

      {/* Tappable word tokens */}
      <div
        className="flex flex-wrap gap-2.5 p-4 rounded-2xl bg-slate-100/70 dark:bg-zinc-900/60 border border-slate-200 dark:border-zinc-800 select-none min-h-[110px] items-center"
        role="group"
        aria-label="Výber slov s pravopisnými chybami"
      >
        {words.map((word, index) => {
          const isSelected = selected.has(index);
          const isCorrectError = errorIndices.has(index);

          return (
            <button
              key={index}
              type="button"
              onClick={() => toggleWord(index)}
              aria-pressed={isSelected}
              className={`inline-flex items-center gap-1.5 px-4 py-2.5 rounded-xl font-medium text-lg transition-all duration-200 cursor-pointer ${
                isSelected
                  ? isCorrectError
                    ? 'bg-emerald-700 dark:bg-emerald-600 text-white shadow-sm ring-2 ring-emerald-500'
                    : 'bg-rose-700 dark:bg-rose-600 text-white shadow-sm ring-2 ring-rose-500'
                  : 'bg-white dark:bg-zinc-800 text-slate-800 dark:text-zinc-200 hover:bg-slate-200 dark:hover:bg-zinc-700 border border-slate-200 dark:border-zinc-700'
              }`}
            >
              <span>{word}</span>
              {isSelected && (
                <span className="shrink-0">
                  {isCorrectError ? (
                    <Check className="w-4 h-4 stroke-[3]" />
                  ) : (
                    <X className="w-4 h-4 stroke-[3]" />
                  )}
                </span>
              )}
            </button>
          );
        })}
      </div>

      <div className="flex items-center justify-between text-sm text-slate-600 dark:text-zinc-400">
        <span>
          Vybrané slová: <strong className="text-slate-900 dark:text-zinc-100">{selected.size}</strong>
        </span>
        <span className="text-xs text-slate-400 dark:text-zinc-500">
          Tip: kliknutím označ alebo odznač slovo
        </span>
      </div>

      <button
        type="button"
        disabled={selected.size === 0}
        onClick={handleSubmit}
        className="w-full py-3 px-6 rounded-xl font-medium bg-[#6750a4] hover:bg-[#563f8f] disabled:opacity-40 disabled:cursor-not-allowed dark:bg-[#a6e55c] dark:hover:bg-[#94d548] text-white dark:text-[#1c3600] shadow-sm transition-colors cursor-pointer"
      >
        Potvrdiť nález
      </button>
    </div>
  );
};
