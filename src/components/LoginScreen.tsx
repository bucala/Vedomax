import React, { useState } from 'react';
import { authService, AuthUser } from '../services/authService';
import { Mail, Lock, Sparkles, Loader2, ArrowLeft } from 'lucide-react';

interface LoginScreenProps {
  onSuccess: (user: AuthUser) => void;
  onEnterDemo: () => void;
  initialMessage?: string;
}

export const LoginScreen: React.FC<LoginScreenProps> = ({
  onSuccess,
  onEnterDemo,
  initialMessage,
}) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(initialMessage || null);
  const [isSuccessMessage, setIsSuccessMessage] = useState(false);

  const handleAuth = async (register: boolean) => {
    const cleanEmail = email.trim();
    if (!cleanEmail.includes('@') || password.length === 0 || (register && password.length < 8)) {
      setMessage(
        register
          ? 'Zadaj e-mail a heslo s aspoň 8 znakmi.'
          : 'Zadaj platný e-mail a heslo.'
      );
      setIsSuccessMessage(false);
      return;
    }

    setBusy(true);
    setMessage(null);

    try {
      if (register) {
        const result = await authService.signUp(cleanEmail, password);
        if (result.requiresEmailConfirm) {
          setMessage(
            'Registráciu dokončíš potvrdením e-mailu. Ak neprišiel, skontroluj spam alebo skús opätovné odoslanie.'
          );
          setIsSuccessMessage(true);
        } else if (result.user) {
          onSuccess(result.user);
        }
      } else {
        const user = await authService.signIn(cleanEmail, password);
        onSuccess(user);
      }
    } catch (err: any) {
      setMessage(err?.message || 'Prihlásenie sa nepodarilo. Skontroluj údaje a pripojenie.');
      setIsSuccessMessage(false);
    } finally {
      setBusy(false);
    }
  };

  const handleResend = async () => {
    const cleanEmail = email.trim();
    if (!cleanEmail.includes('@') || cleanEmail.endsWith('@')) {
      setMessage('Najprv zadaj svoj e-mail.');
      setIsSuccessMessage(false);
      return;
    }

    setBusy(true);
    setMessage(null);

    try {
      await authService.resendConfirmation(cleanEmail);
      setMessage('Ak účet čaká na potvrdenie, e-mail bude odoslaný. Skontroluj aj spam.');
      setIsSuccessMessage(true);
    } catch (err: any) {
      setMessage(err?.message || 'E-mail sa nepodarilo odoslať. Skús to neskôr.');
      setIsSuccessMessage(false);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-zinc-950 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md px-4">
        <button
          type="button"
          onClick={onEnterDemo}
          className="inline-flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wider text-[#6750a4] dark:text-[#a6e55c] mb-6 hover:underline cursor-pointer"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Späť do demo režimu</span>
        </button>

        <div className="flex items-center justify-center gap-2 mb-2">
          <div className="w-10 h-10 rounded-2xl bg-[#6750a4] dark:bg-[#a6e55c] flex items-center justify-center text-white dark:text-[#1c3600] font-bold text-xl shadow-md">
            V
          </div>
          <h1 className="text-2xl font-black tracking-tight text-slate-900 dark:text-zinc-100">
            Vedomax
          </h1>
        </div>
        <p className="text-center text-sm font-medium text-slate-600 dark:text-zinc-400">
          Uč sa. Hraj sa. Napreduj.
        </p>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md px-4">
        <div className="bg-white dark:bg-zinc-900 py-8 px-6 shadow-sm border border-slate-200 dark:border-zinc-800 rounded-3xl sm:px-10 space-y-5">
          <h2 className="text-xl font-bold text-slate-900 dark:text-zinc-100">
            Prihlásenie do účtu
          </h2>

          {message && (
            <div
              className={`p-3.5 rounded-xl text-sm font-medium ${
                isSuccessMessage
                  ? 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-800 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-800'
                  : 'bg-rose-50 dark:bg-rose-950/40 text-rose-800 dark:text-rose-300 border border-rose-200 dark:border-rose-800'
              }`}
            >
              {message}
            </div>
          )}

          <div className="space-y-4">
            <div>
              <label
                htmlFor="email"
                className="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-zinc-400 mb-1"
              >
                E-mail
              </label>
              <div className="relative flex items-center">
                <input
                  id="email"
                  type="email"
                  autoComplete="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="ziak@skola.sk"
                  className="w-full pl-10 pr-4 py-3 rounded-xl border border-slate-300 dark:border-zinc-700 bg-white dark:bg-zinc-950 text-slate-900 dark:text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-[#6750a4] dark:focus:ring-[#a6e55c]"
                />
                <Mail className="w-5 h-5 absolute left-3 text-slate-400 pointer-events-none" />
              </div>
            </div>

            <div>
              <label
                htmlFor="password"
                className="block text-xs font-semibold uppercase tracking-wider text-slate-500 dark:text-zinc-400 mb-1"
              >
                Heslo
              </label>
              <div className="relative flex items-center">
                <input
                  id="password"
                  type="password"
                  autoComplete="current-password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full pl-10 pr-4 py-3 rounded-xl border border-slate-300 dark:border-zinc-700 bg-white dark:bg-zinc-950 text-slate-900 dark:text-zinc-100 text-sm focus:outline-none focus:ring-2 focus:ring-[#6750a4] dark:focus:ring-[#a6e55c]"
                />
                <Lock className="w-5 h-5 absolute left-3 text-slate-400 pointer-events-none" />
              </div>
            </div>

            <div className="pt-2 space-y-2.5">
              <button
                type="button"
                disabled={busy}
                onClick={() => handleAuth(false)}
                className="w-full flex items-center justify-center gap-2 py-3 px-4 rounded-xl font-medium bg-[#6750a4] hover:bg-[#563f8f] disabled:opacity-50 dark:bg-[#a6e55c] dark:hover:bg-[#94d548] text-white dark:text-[#1c3600] shadow-sm transition-colors cursor-pointer"
              >
                {busy && <Loader2 className="w-4 h-4 animate-spin" />}
                <span>Prihlásiť sa</span>
              </button>

              <button
                type="button"
                disabled={busy}
                onClick={() => handleAuth(true)}
                className="w-full py-2.5 px-4 rounded-xl font-medium text-slate-700 dark:text-zinc-300 hover:bg-slate-100 dark:hover:bg-zinc-800 border border-slate-200 dark:border-zinc-700 transition-colors cursor-pointer"
              >
                Vytvoriť účet
              </button>

              <button
                type="button"
                disabled={busy}
                onClick={handleResend}
                className="w-full py-2 text-xs font-medium text-slate-500 dark:text-zinc-400 hover:text-slate-800 dark:hover:text-zinc-200 transition-colors cursor-pointer text-center block"
              >
                Poslať potvrdzovací e-mail znova
              </button>
            </div>
          </div>

          <p className="text-[11px] text-center text-slate-400 dark:text-zinc-500 pt-2 border-t border-slate-100 dark:border-zinc-800">
            Používaj prezývku. Registráciu a pravidlá ochrany údajov preber so zákonným zástupcom.
          </p>
        </div>
      </div>
    </div>
  );
};
