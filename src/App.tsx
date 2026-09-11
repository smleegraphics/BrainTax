import { lazy, Suspense, useEffect } from 'react';
import Home from './Home';
import { useHashPath } from './lib/router';

// Each game loads on demand so the home screen stays tiny on mobile data.
const ChessPage = lazy(() => import('./chess/ChessPage'));
const GeoHome = lazy(() => import('./geo/GeoHome'));
const GeoQuiz = lazy(() => import('./geo/GeoQuiz'));

export default function App() {
  const path = useHashPath();
  // Block body on purpose: Chrome's scrollTo returns a Promise, and React would
  // treat a returned value as the effect's cleanup function.
  useEffect(() => {
    window.scrollTo(0, 0);
  }, [path]);

  const [section, mode, region] = path.split('/').filter(Boolean);
  let page;
  if (section === 'chess') {
    page = <ChessPage />;
  } else if (section === 'geo') {
    page = mode ? <GeoQuiz key={path} modeSlug={mode} regionSlug={region} /> : <GeoHome />;
  } else {
    page = <Home />;
  }

  return (
    <div className="app">
      <Suspense fallback={<div className="empty"><div className="spinner" /></div>}>{page}</Suspense>
    </div>
  );
}
