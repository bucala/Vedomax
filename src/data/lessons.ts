import { Lesson } from '../types';

export const DEMO_LESSONS: Lesson[] = [
  {
    id: 1,
    title: 'Matematika • Zachráň prieskumníka',
    seconds: 120,
    animation: '/assets/animations/success.json',
    questions: [
      {
        id: 'math',
        text: 'Rebrík vedie k prieskumníkovi. Stena má výšku 4 m a päta rebríka je 3 m od steny. Aký dlhý musí byť rebrík?',
        mechanic: 'puzzle_calc',
        content: { a: 3, b: 4 },
      },
    ],
  },
  {
    id: 2,
    title: 'Slovenčina • Vetriť chybu',
    seconds: 30,
    animation: '/assets/animations/success.json',
    questions: [
      {
        id: 'detective',
        text: 'Odhaľ dve pravopisné chyby v príspevku.',
        mechanic: 'detective',
        content: {
          words: ['Moji', 'kamarátiy', 'dnes', 'navštívili', 'hrad.', 'Bolily', 'nadšení!'],
          error_indices: [1, 5],
        },
      },
    ],
  },
  {
    id: 3,
    title: 'Geografia • Slepá mapa',
    seconds: 60,
    animation: '/assets/animations/success.json',
    questions: [
      {
        id: 'geo',
        text: 'Kde sa nachádza Bojnický zámok?',
        mechanic: 'geo_click',
        content: { map: '/assets/maps/slovakia.png' },
      },
    ],
  },
];
