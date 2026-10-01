import Link from "next/link";
import Image from "next/image";

interface ArticleCardProps {
  id: string;
  title: string;
  description: string;
  image: string;
}

export default function ArticleCard({ id, title, description, image }: ArticleCardProps) {
  return (
    <article className="article-card travella-style">
      <Link href={`/article/${id}`} className="article-media">
        <Image src={image} alt={title} width={600} height={400} style={{ objectFit: "cover", width: "100%", height: "100%" }} />
      </Link>
      <div className="article-content">
        <h3 className="article-title">{title}</h3>
        <p className="article-desc">{description}</p>
      </div>
    </article>
  );
}
