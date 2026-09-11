import type { ReactNode } from 'react';

interface HeaderProps {
  title: string;
  /** Hash route the back button returns to. */
  back?: string;
  right?: ReactNode;
}

export function Header({ title, back = '#/', right }: HeaderProps) {
  return (
    <header className="topbar">
      <a className="icon-btn" href={back} aria-label="Back">
        <ChevronLeft />
      </a>
      <h1 className="topbar-title">{title}</h1>
      <div className="topbar-right">{right}</div>
    </header>
  );
}

export function ChevronLeft() {
  return (
    <svg viewBox="0 0 24 24" width="24" height="24" aria-hidden="true">
      <path d="M15 5l-7 7 7 7" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

export function ChevronRight() {
  return (
    <svg className="chevron" viewBox="0 0 24 24" width="20" height="20" aria-hidden="true">
      <path d="M9 5l7 7-7 7" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}
