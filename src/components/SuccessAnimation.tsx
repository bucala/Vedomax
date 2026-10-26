import React, { useEffect, useRef } from 'react';
import lottie from 'lottie-web';
import { Sparkles } from 'lucide-react';

interface SuccessAnimationProps {
  animationPath?: string;
}

export const SuccessAnimation: React.FC<SuccessAnimationProps> = ({
  animationPath = '/assets/animations/success.json',
}) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const [failed, setFailed] = React.useState(false);

  useEffect(() => {
    if (!containerRef.current) return;

    // Check prefers-reduced-motion
    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    let anim: any = null;
    try {
      anim = lottie.loadAnimation({
        container: containerRef.current,
        renderer: 'svg',
        loop: false,
        autoplay: !prefersReducedMotion,
        path: animationPath,
      });

      anim.addEventListener('data_failed', () => setFailed(true));
      anim.addEventListener('error', () => setFailed(true));
    } catch {
      setFailed(true);
    }

    return () => {
      if (anim) {
        anim.destroy();
      }
    };
  }, [animationPath]);

  if (failed) {
    return (
      <div className="w-32 h-32 flex items-center justify-center text-amber-500 animate-pulse">
        <Sparkles className="w-20 h-20" />
      </div>
    );
  }

  return (
    <div
      ref={containerRef}
      className="w-44 h-44 flex items-center justify-center"
      aria-label="Animácia úspešného splnenia misie"
    />
  );
};
