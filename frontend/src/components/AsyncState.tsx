type MessageStateProps = {
  message: string;
};

export function LoadingState({ message }: MessageStateProps) {
  return (
    <div className="state state-loading" role="status" aria-live="polite">
      <span className="spinner" aria-hidden="true" />
      <p>{message}</p>
    </div>
  );
}

export function EmptyState({ message }: MessageStateProps) {
  return (
    <div className="state state-empty">
      <p>{message}</p>
    </div>
  );
}

export function ErrorState({ message }: MessageStateProps) {
  return (
    <div className="state state-error" role="alert">
      <strong>Something went wrong</strong>
      <p>{message}</p>
    </div>
  );
}
