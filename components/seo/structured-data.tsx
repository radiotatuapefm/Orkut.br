'use client'

export function StructuredData() {
  const structuredData = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "WebSite",
        "@id": "https://orkut-864g4zydz-astridnielsen-labs-projects.vercel.app/#website",
        "url": "https://orkut-864g4zydz-astridnielsen-labs-projects.vercel.app",
        "name": "Orkut Retrô - A rede social que você ama",
        "description": "Reviva os momentos especiais do Orkut com recursos modernos de voz e chamadas. Desenvolvido por Julio Campos Machado da Like Look Solutions.",
        "publisher": {
          "@id": "https://orkut-864g4zydz-astridnielsen-labs-projects.vercel.app/#organization"
        },
        "potentialAction": [
          {
            "@type": "SearchAction",
            "target": {
              "@type": "EntryPoint",
              "urlTemplate": "https://orkut-864g4zydz-astridnielsen-labs-projects.vercel.app/buscar?q={search_term_string}"
            },
            "query-input": "required name=search_term_string"
          }
        ],
        "inLanguage": "pt-BR"
      },
      {
        "@type": "Organization",
        "@id": "https://orkut-864g4zydz-astridnielsen-labs-projects.vercel.app/#organization",
        "name": "Like Look Solutions",
        "url": "https://likelook.wixsite.com/solutions",
        "logo": {
          "@type": "ImageObject",
          "inLanguage": "pt-BR",
          "url": "https://orkut-864g4zydz-astridnielsen-labs-projects.vercel.app/favicon.svg",
          "contentUrl": "https://orkut-864g4zydz-astridnielsen-labs-projects.vercel.app/favicon.svg",
          "width": 32,
          "height": 32,
          "caption": "Like Look Solutions"
        },
        "contactPoint": [
          {
            "@type": "ContactPoint",
            "telephone": "+5511992946628",
            "contactType": "customer service",
            "areaServed": "BR",
            "availableLanguage": "Portuguese"
          }
        ],
        "address": {
          "@type": "PostalAddress",
          "streetAddress": "Rua Dante Pellacani, 92",
          "addressLocality": "São Paulo",
          "addressRegion": "SP",
          "addressCountry": "BR"
        },
        "founder": {
          "@type": "Person",
          "name": "Julio Campos Machado",
          "jobTitle": "Developer & Founder",
          "email": "juliocamposmachado@gmail.com",
          "telephone": "+5511992946628"
        }
      },
      {
        "@type": "WebApplication",
        "name": "Orkut Retrô",
        "url": "https://orkut-864g4zydz-astridnielsen-labs-projects.vercel.app",
        "description": "A rede social que você ama - reviva os momentos especiais do Orkut",
        "applicationCategory": "SocialNetworkingApplication",
        "operatingSystem": "Web Browser",
        "browserRequirements": "Modern web browser with JavaScript support",
        "permissions": "microphone (optional for voice features)",
        "author": {
          "@type": "Person",
          "name": "Julio Campos Machado",
          "url": "https://likelook.wixsite.com/solutions"
        },
        "provider": {
          "@id": "https://orkut-864g4zydz-astridnielsen-labs-projects.vercel.app/#organization"
        },
        "offers": {
          "@type": "Offer",
          "price": "0",
          "priceCurrency": "BRL",
          "availability": "https://schema.org/InStock"
        },
        "featureList": [
          "Perfis de usuário personalizados",
          "Sistema de recados",
          "Comunidades temáticas",
          "Busca de amigos",
          "Interface nostálgica",
          "Recursos modernos de voz",
          "Chamadas integradas"
        ]
      },
      {
        "@type": "SoftwareApplication",
        "name": "Orkut Retrô",
        "applicationCategory": "SocialNetworkingApplication",
        "operatingSystem": "Web",
        "url": "https://orkut-864g4zydz-astridnielsen-labs-projects.vercel.app",
        "author": {
          "@type": "Person",
          "name": "Julio Campos Machado"
        },
        "datePublished": "2025-08-20",
        "description": "Aplicação web que recria a experiência nostálgica do Orkut com tecnologia moderna",
        "screenshot": "https://orkut-864g4zydz-astridnielsen-labs-projects.vercel.app/redes-sociais.jpg",
        "aggregateRating": {
          "@type": "AggregateRating",
          "ratingValue": "4.8",
          "ratingCount": "150",
          "bestRating": "5",
          "worstRating": "1"
        }
      }
    ]
  }

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{
        __html: JSON.stringify(structuredData, null, 2)
      }}
    />
  )
}
