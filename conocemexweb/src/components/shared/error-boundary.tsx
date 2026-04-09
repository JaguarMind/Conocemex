'use client';

import { Component, type ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(): State {
    return { hasError: true };
  }

  componentDidCatch(error: Error) {
    // Ignore hydration/removeChild errors — they're from browser extensions
    if (
      error.message?.includes('removeChild') ||
      error.message?.includes('Hydration') ||
      error.message?.includes('hydration')
    ) {
      this.setState({ hasError: false });
      return;
    }
    console.error('[ErrorBoundary]', error);
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback ?? (
        <div className="flex flex-col items-center justify-center min-h-screen gap-4 p-6">
          <span className="material-symbols-outlined text-5xl text-on-surface-variant/40">error</span>
          <p className="text-on-surface-variant font-medium">Something went wrong</p>
          <button
            onClick={() => {
              this.setState({ hasError: false });
              window.location.reload();
            }}
            className="bg-primary-container text-on-primary-container px-6 py-2 rounded-full font-bold text-sm"
          >
            Reload
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}
