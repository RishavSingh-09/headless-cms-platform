export async function getServerSideProps() {
  const api = process.env.NEXT_PUBLIC_API_URL || 'http://cms-backend:1337';
  let articles = [];
  try {
    const r = await fetch(`${api}/api/articles`);
    const j = await r.json();
    articles = j.data || [];
  } catch (e) {
    articles = [{ id: 0, title: 'Backend unreachable', body: String(e) }];
  }
  return { props: { articles } };
}

export default function Home({ articles }) {
  return (
    <main style={{ fontFamily: 'system-ui', maxWidth: 720, margin: '40px auto', padding: 16 }}>
      <h1>Headless CMS Platform</h1>
      <p>Strapi + Next.js on Amazon EKS</p>
      <ul>
        {articles.map((a) => (
          <li key={a.id}>
            <strong>{a.title}</strong> — {a.body}
          </li>
        ))}
      </ul>
    </main>
  );
}
