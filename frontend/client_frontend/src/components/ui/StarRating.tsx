import GoogleSymbol from "./GoogleSymbol";

export default function StarRating({ rating }: { rating: number }) {
  const count = Math.max(0, Math.min(5, Math.round(rating)));
  return <span role="img" aria-label={`${rating} trên 5 sao`} className="inline-flex items-center">
    {Array.from({ length: 5 }, (_, index) => <GoogleSymbol key={index} name="star" size={16} filled={index < count} />)}
  </span>;
}
