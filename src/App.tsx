import React, { useState, useEffect } from 'react';
import { Lesson } from './types';
import { DEMO_LESSONS } from './data/lessons';
import {
  DemoLearningRepository,
  LocalLearningRepository,
  LocalProfileRepository,
  SupabaseLearningRepository,
  isSupabaseConfigured,
  supabase,
} from './services/learningRepository';
import { authService, AuthUser } from './services/authService';
import { Dashboard } from './components/Dashboard';
import { LessonScreen } from './components/LessonScreen';
import { LoginScreen } from './components/LoginScreen';

export const App: React.FC = () => {
  // Demo mode is default true as in Flutter demo.json and main.dart
  const [isDemo, setIsDemo] = useState(true);
  const [currentUser, setCurrentUser] = useState<AuthUser | null>(null);
  const [showLogin, setShowLogin] = useState(false);
  const [activeLesson, setActiveLesson] = useState<Lesson | null>(null);
  const [lessons, setLessons] = useState<Lesson[]>(DEMO_LESSONS);

  // Dark mode setup
  const [isDark, setIsDark] = useState(() => {
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem('vedomax_theme');
      if (saved) return saved === 'dark';
      return window.matchMedia('(prefers-color-scheme: dark)').matches;
    }
    return false;
  });

  useEffect(() => {
    const root = document.documentElement;
    if (isDark) {
      root.classList.add('dark');
      localStorage.setItem('vedomax_theme', 'dark');
    } else {
      root.classList.remove('dark');
      localStorage.setItem('vedomax_theme', 'light');
    }
  }, [isDark]);

  // Initial user check
  useEffect(() => {
    const user = authService.getCurrentUser();
    if (user) {
      setCurrentUser(user);
    }

    if (isSupabaseConfigured && supabase) {
      supabase.auth.getSession().then(({ data }) => {
        if (data.session?.user) {
          setCurrentUser({
            id: data.session.user.id,
            email: data.session.user.email || '',
          });
        }
      });

      const { data: authListener } = supabase.auth.onAuthStateChange((_event, session) => {
        if (session?.user) {
          setCurrentUser({
            id: session.user.id,
            email: session.user.email || '',
          });
        } else {
          setCurrentUser(null);
        }
      });

      return () => {
        authListener.subscription.unsubscribe();
      };
    }
  }, []);

  // Determine repositories
  const getRepositories = () => {
    if (isDemo || !currentUser) {
      return {
        learning: new DemoLearningRepository(),
        profile: undefined,
      };
    }

    if (isSupabaseConfigured && supabase) {
      return {
        learning: new SupabaseLearningRepository(supabase),
        profile: new LocalProfileRepository(),
      };
    }

    return {
      learning: new LocalLearningRepository(currentUser.id),
      profile: new LocalProfileRepository(),
    };
  };

  const { learning: currentLearningRepo, profile: currentProfileRepo } = getRepositories();

  // Load lessons from repo
  useEffect(() => {
    currentLearningRepo.lessons().then((res) => {
      setLessons(res);
    });
  }, [isDemo, currentUser]);

  const handleSignOut = async () => {
    await authService.signOut();
    setCurrentUser(null);
    setIsDemo(true);
    setShowLogin(false);
  };

  const handleAuthSuccess = (user: AuthUser) => {
    setCurrentUser(user);
    setIsDemo(false);
    setShowLogin(false);
  };

  const handleToggleTheme = () => {
    setIsDark((prev) => !prev);
  };

  // If in lesson screen
  if (activeLesson) {
    return (
      <LessonScreen
        lesson={activeLesson}
        repository={currentLearningRepo}
        isDemo={isDemo}
        onBack={() => setActiveLesson(null)}
        onSyncProfile={() => {
          // Trigger profile reload
        }}
      />
    );
  }

  // If user requested login
  if (showLogin && !currentUser) {
    return (
      <LoginScreen
        onSuccess={handleAuthSuccess}
        onEnterDemo={() => {
          setShowLogin(false);
          setIsDemo(true);
        }}
      />
    );
  }

  return (
    <Dashboard
      lessons={lessons}
      repository={currentLearningRepo}
      profileRepo={currentProfileRepo}
      currentUser={currentUser}
      isDemo={isDemo}
      onSelectLesson={(lesson) => setActiveLesson(lesson)}
      onSignOut={handleSignOut}
      onSwitchToAuth={() => {
        if (!currentUser) {
          setShowLogin(true);
        } else {
          setIsDemo(false);
        }
      }}
      onSwitchToDemo={() => setIsDemo(true)}
      isDark={isDark}
      onToggleTheme={handleToggleTheme}
    />
  );
};
