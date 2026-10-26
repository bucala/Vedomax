import React, { useState } from 'react';
import { Question } from '../../types';
import { Shield } from 'lucide-react';

interface PuzzleCalcProps {
  question: Question;
  onAnswer: (answer: number) => void;
}

export const PuzzleCalc: React.FC<PuzzleCalcProps> = ({ question: _q, onAnswer }) => {
  const [value, setValue] = useState('');
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    const clean = value.trim().replace(',', '.');
    const num = parseFloat(clean);
    if (isNaN(num) || !isFinite(num) || num <= 0) {
      setError('Zadaj kladnú dĺžku v metroch.');
      return;
    }
    setError(null);
    onAnswer(num);
  };

  return (
    <div className="flex flex-col items-center w-full max-w-md mx-auto">
      {/* SVG drawing matching Flutter TrianglePainter */}
      <div
        className="w-[300px] h-[220px] relative select-none"
        aria-label="Pravouhlý trojuholník: základňa 3 metre, výška 4 metre, prepona je rebrík."
      >
        <svg
          viewBox="0 0 300 220"
          className="w-full h-full stroke-[#6750a4] dark:stroke-[#a6e55c]"
          fill="none"
        >
          {/* Main triangle: (50, 175) -> (245, 175) -> (245, 30) -> close */}
          <path
            d="M 50 175 L 245 175 L 245 30 Z"
            strokeWidth="5"
            strokeLinejoin="round"
          />
          {/* Right-angle symbol at (245, 175): (225, 175) -> (225, 155) -> (245, 155) */}
          <path
            d="M 225 175 L 225 155 L 245 155"
            strokeWidth="2"
            fill="none"
          />
          {/* Labels */}
          <text
            x="135"
            y="198"
            className="text-[17px] font-semibold fill-slate-800 dark:fill-zinc-200 stroke-none"
            textAnchor="middle"
          >
            3 m
          </text>
          <text
            x="268"
            y="110"
            className="text-[17px] font-semibold fill-slate-800 dark:fill-zinc-200 stroke-none"
            textAnchor="start"
          >
            4 m
          </text>
          <text
            x="125"
            y="95"
            className="text-[17px] font-semibold fill-slate-800 dark:fill-zinc-200 stroke-none"
            textAnchor="middle"
          >
            c = ?
          </text>
          {/* Explorer star at the top vertex (245, 30) */}
          <text
            x="245"
            y="22"
            className="text-[24px] font-bold fill-amber-500 stroke-none"
            textAnchor="middle"
          >
            ★
          </text>
        </svg>
      </div>

      <div className="text-sm font-medium text-slate-600 dark:text-zinc-400 mt-2 mb-4">
        Pomôcka: a² + b² = c²
      </div>

      <form onSubmit={handleSubmit} className="w-full space-y-4">
        <div className="relative">
          <label className="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-zinc-400 mb-1">
            Dĺžka rebríka
          </label>
          <div className="relative flex items-center">
            <input
              type="text"
              inputMode="decimal"
              value={value}
              onChange={(e) => {
                setValue(e.target.value);
                if (error) setError(null);
              }}
              placeholder="napr. 5"
              className="w-full px-4 py-3 rounded-xl border border-slate-300 dark:border-zinc-700 bg-white dark:bg-zinc-900 text-slate-900 dark:text-zinc-100 pr-12 focus:outline-none focus:ring-2 focus:ring-[#6750a4] dark:focus:ring-[#a6e55c]"
            />
            <span className="absolute right-4 text-slate-400 dark:text-zinc-500 font-medium">
              m
            </span>
          </div>
          {error && <p className="mt-1 text-sm text-red-600 dark:text-red-400">{error}</p>}
        </div>

        <button
          type="submit"
          className="w-full flex items-center justify-center gap-2 py-3 px-6 rounded-xl font-medium bg-[#6750a4] hover:bg-[#563f8f] dark:bg-[#a6e55c] dark:hover:bg-[#94d548] text-white dark:text-[#1c3600] shadow-sm transition-colors cursor-pointer"
        >
          <Shield className="w-5 h-5" />
          <span>Zachrániť prieskumníka</span>
        </button>
      </form>
    </div>
  );
};
