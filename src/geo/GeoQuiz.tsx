import { lazy, Suspense, useEffect, useState } from 'react';
import { Header } from '../components/Header';
import { load, save } from '../lib/storage';
import { DEFAULT_GEO_STATS, GEO_STATS_KEY } from '../lib/stats';
import { useTimers } from '../lib/useTimers';
import { parseRegion, type Country, type RegionFilter } from './countries';
import { Flag, preloadFlag } from './Flag';
import { bestKey, GEO_MODES, isGeoMode, makeRound, type GeoMode, type Question } from './quiz';

const WorldMap = lazy(() => import('./WorldMap'));

const AUTO_ADVANCE_MS = 900;

export default function GeoQuizRoute({ modeSlug, regionSlug }: { modeSlug: string; regionSlug?: string }) {
  if (!isGeoMode(modeSlug)) {
    return (
      <>
        <Header title="Geography" back="#/geo" />
        <div className="empty">
          <p>That quiz doesn’t exist.</p>
          <a className="btn" href="#/geo">
            Choose a quiz
          </a>
        </div>
      </>
    );
  }
  return <GeoQuiz mode={modeSlug} region={parseRegion(regionSlug)} />;
}

function GeoQuiz({ mode, region }: { mode: GeoMode; region: RegionFilter }) {
  const [round, setRound] = useState(() => makeRound(mode, region));
  const [index, setIndex] = useState(0);
  const [picked, setPicked] = useState<string | null>(null);
  const [results, setResults] = useState<boolean[]>([]);
  const [previousBest, setPreviousBest] = useState<number | null>(null);
  const timers = useTimers();

  const question: Question | undefined = round[index];
  const score = results.filter(Boolean).length;

  // Warm the cache for the next question's flags so they appear instantly.
  useEffect(() => {
    const next = round[index + 1];
    if (!next) return;
    if (mode === 'flags') preloadFlag(next.answer.code);
    if (mode === 'pick-flag') next.options.forEach((o) => preloadFlag(o.code));
  }, [round, index, mode]);

  const advance = () => {
    timers.clear();
    setPicked(null);
    setIndex((i) => i + 1);
  };

  const recordRound = (finalScore: number) => {
    const stats = load(GEO_STATS_KEY, DEFAULT_GEO_STATS);
    const key = bestKey(mode, region);
    const best = stats.best[key] ?? 0;
    setPreviousBest(best);
    save(GEO_STATS_KEY, {
      ...stats,
      rounds: stats.rounds + 1,
      best: { ...stats.best, [key]: Math.max(best, finalScore) },
    });
  };

  const choose = (option: Country) => {
    if (!question || picked) return;
    const correct = option.code === question.answer.code;
    const nextResults = [...results, correct];
    setPicked(option.code);
    setResults(nextResults);
    if (nextResults.length === round.length) recordRound(nextResults.filter(Boolean).length);
    if (correct) timers.later(advance, AUTO_ADVANCE_MS);
  };

  const restart = () => {
    timers.clear();
    setRound(makeRound(mode, region));
    setIndex(0);
    setPicked(null);
    setResults([]);
    setPreviousBest(null);
  };

  const title = region === 'World' ? GEO_MODES[mode].title : `${GEO_MODES[mode].title} · ${region}`;

  return (
    <>
      <Header
        title={title}
        back="#/geo"
        right={question && <span className="counter">{index + 1}/{round.length}</span>}
      />
      <ol className="progress" aria-label={`${score} correct so far`}>
        {round.map((q, i) => (
          <li
            key={q.answer.code}
            className={i < results.length ? (results[i] ? 'progress-good' : 'progress-bad') : i === index ? 'progress-now' : ''}
          />
        ))}
      </ol>

      {question ? (
        <main className="quiz">
          <Prompt mode={mode} answer={question.answer} />
          <Options mode={mode} question={question} picked={picked} onChoose={choose} />
          <div className="quiz-footer" aria-live="polite">
            {picked && <Feedback mode={mode} question={question} picked={picked} />}
            {picked && picked !== question.answer.code && (
              <button type="button" className="btn btn-wide" onClick={advance}>
                {index + 1 === round.length ? 'See results' : 'Next'}
              </button>
            )}
          </div>
        </main>
      ) : (
        <Summary
          mode={mode}
          round={round}
          results={results}
          previousBest={previousBest}
          onRestart={restart}
        />
      )}
    </>
  );
}

function Prompt({ mode, answer }: { mode: GeoMode; answer: Country }) {
  switch (mode) {
    case 'flags':
      return (
        <>
          <Flag code={answer.code} className="flag-hero" />
          <h2 className="prompt">Which country’s flag is this?</h2>
        </>
      );
    case 'pick-flag':
      return (
        <h2 className="prompt">
          Which is the flag of <strong>{answer.name}</strong>?
        </h2>
      );
    case 'capitals':
      return (
        <h2 className="prompt">
          What is the capital of <strong>{answer.name}</strong>?
        </h2>
      );
    case 'map':
      return (
        <>
          <Suspense fallback={<div className="map-frame" />}>
            <WorldMap numeric={answer.numeric} />
          </Suspense>
          <h2 className="prompt">Which country is highlighted?</h2>
        </>
      );
  }
}

interface OptionsProps {
  mode: GeoMode;
  question: Question;
  picked: string | null;
  onChoose: (option: Country) => void;
}

function Options({ mode, question, picked, onChoose }: OptionsProps) {
  const stateOf = (option: Country) => {
    if (!picked) return '';
    if (option.code === question.answer.code) return ' option-correct';
    return option.code === picked ? ' option-wrong' : ' option-dim';
  };

  if (mode === 'pick-flag') {
    return (
      <div className="flag-grid">
        {question.options.map((o) => (
          <button
            key={o.code}
            type="button"
            className={`flag-option${stateOf(o)}`}
            onClick={() => onChoose(o)}
            disabled={picked !== null}
            aria-label={picked ? o.name : `Option ${question.options.indexOf(o) + 1}`}
          >
            <Flag code={o.code} />
            {picked && <span className="flag-caption">{o.name}</span>}
          </button>
        ))}
      </div>
    );
  }

  return (
    <div className="options">
      {question.options.map((o) => (
        <button
          key={o.code}
          type="button"
          className={`option${stateOf(o)}`}
          onClick={() => onChoose(o)}
          disabled={picked !== null}
        >
          {mode === 'capitals' ? o.capital : o.name}
        </button>
      ))}
    </div>
  );
}

function Feedback({ mode, question, picked }: { mode: GeoMode; question: Question; picked: string }) {
  const { answer } = question;
  if (picked === answer.code) return <p className="status status-good">Correct!</p>;
  let text: string;
  if (mode === 'capitals') {
    text = `The capital of ${answer.name} is ${answer.capital}.`;
  } else if (mode === 'pick-flag') {
    const choice = question.options.find((o) => o.code === picked);
    text = `That’s the flag of ${choice?.name}.`;
  } else {
    text = `That’s ${answer.name}.`;
  }
  return <p className="status status-bad">{text}</p>;
}

interface SummaryProps {
  mode: GeoMode;
  round: Question[];
  results: boolean[];
  previousBest: number | null;
  onRestart: () => void;
}

function Summary({ mode, round, results, previousBest, onRestart }: SummaryProps) {
  const score = results.filter(Boolean).length;
  const misses = round.filter((_, i) => !results[i]);
  const isNewBest = previousBest !== null && score > previousBest;

  return (
    <main className="summary">
      <p className="score">
        {score}
        <span>/{round.length}</span>
      </p>
      <p className="meta">
        {isNewBest ? 'New best!' : previousBest !== null ? `Best: ${Math.max(previousBest, score)}/${round.length}` : ''}
      </p>

      {misses.length > 0 && (
        <section className="review">
          <h2>Review</h2>
          <ul>
            {misses.map(({ answer }) => (
              <li key={answer.code}>
                <Flag code={answer.code} className="flag-small" />
                <span>
                  <strong>{answer.name}</strong>
                  {mode === 'capitals' && <span className="review-sub">{answer.capital}</span>}
                </span>
              </li>
            ))}
          </ul>
        </section>
      )}

      <div className="actions actions-stack">
        <button type="button" className="btn btn-wide" onClick={onRestart}>
          Play again
        </button>
        <a className="btn btn-secondary btn-wide" href="#/geo">
          Change quiz
        </a>
      </div>
    </main>
  );
}
