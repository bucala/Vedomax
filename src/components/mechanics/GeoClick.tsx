import React, { useState, useRef } from 'react';
import { Question } from '../../types';
import { MapPin } from 'lucide-react';

interface GeoClickProps {
  question: Question;
  onAnswer: (coords: { x: number; y: number }) => void;
}

export const GeoClick: React.FC<GeoClickProps> = ({ question, onAnswer }) => {
  const [point, setPoint] = useState<{ x: number; y: number } | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  const handlePointerDown = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!containerRef.current) return;
    const rect = containerRef.current.getBoundingClientRect();
    const x = Math.min(Math.max((e.clientX - rect.left) / rect.width, 0), 1);
    const y = Math.min(Math.max((e.clientY - rect.top) / rect.height, 0), 1);
    setPoint({ x, y });
  };

  const handleSubmit = () => {
    if (!point) return;
    onAnswer(point);
  };

  const mapSrc = question.content.map || '/assets/maps/slovakia.png';

  return (
    <div className="flex flex-col items-center w-full max-w-xl mx-auto space-y-4">
      <p className="text-sm font-medium text-slate-700 dark:text-zinc-300 text-center">
        Ťukni na mapu. Značku môžeš pred potvrdením presunúť.
      </p>

      {/* 2:1 Aspect ratio map container */}
      <div
        ref={containerRef}
        onClick={handlePointerDown}
        role="region"
        aria-label="Zjednodušená mapa Slovenska. Dotyková úloha; vyžaduje vizuálnu orientáciu."
        className="w-full aspect-[2/1] relative select-none rounded-2xl overflow-hidden border-2 border-slate-300 dark:border-zinc-700 bg-slate-200 dark:bg-zinc-800 cursor-crosshair shadow-inner"
      >
        <img
          src={mapSrc}
          alt="Slepá mapa Slovenska"
          className="w-full h-full object-fill pointer-events-none"
        />

        {point && (
          <div
            style={{
              left: `${point.x * 100}%`,
              top: `${point.y * 100}%`,
              transform: 'translate(-50%, -100%)',
            }}
            className="absolute pointer-events-none drop-shadow-md text-orange-600 animate-bounce duration-500"
          >
            <MapPin className="w-8 h-8 fill-orange-500 text-orange-700" />
          </div>
        )}
      </div>

      <button
        type="button"
        disabled={!point}
        onClick={handleSubmit}
        className="w-full py-3 px-6 rounded-xl font-medium bg-[#6750a4] hover:bg-[#563f8f] disabled:opacity-40 disabled:cursor-not-allowed dark:bg-[#a6e55c] dark:hover:bg-[#94d548] text-white dark:text-[#1c3600] shadow-sm transition-colors cursor-pointer"
      >
        Potvrdiť polohu
      </button>

      <p className="text-xs text-slate-500 dark:text-zinc-400 text-center">
        Tréningová mapa • tolerancia 6 % rozmerov obrázka
      </p>
    </div>
  );
};
