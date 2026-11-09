-- BlackSolutions: contagem de visitas e cliques dos três sites
-- Guarda só o site, a página, o tipo de clique, a origem e o tipo de aparelho. Nenhum dado pessoal.

create table if not exists public.site_cliques (
  id         bigserial primary key,
  criado_em  timestamptz not null default now(),
  site       text not null,
  pagina     text not null default '',
  evento     text not null,
  alvo       text not null default '',
  origem     text not null default '',
  aparelho   text not null default ''
);
alter table public.site_cliques enable row level security;
create index if not exists site_cliques_data on public.site_cliques (criado_em desc);

-- O navegador só consegue gravar por esta função (não lê nada)
create or replace function public.registrar_clique(p_site text, p_pagina text, p_evento text, p_alvo text,
                                                  p_origem text, p_aparelho text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_site not in ('blacksolutions', 'blackflow', 'lexcalc') then return; end if;
  if p_evento not in ('visita', 'clique', 'whatsapp', 'download', 'pagamento', 'cadastro', 'compra') then return; end if;
  insert into public.site_cliques (site, pagina, evento, alvo, origem, aparelho)
  values (p_site, left(coalesce(p_pagina, ''), 120), p_evento, left(coalesce(p_alvo, ''), 60),
          left(coalesce(p_origem, ''), 60), left(coalesce(p_aparelho, ''), 20));
end $$;
revoke all on function public.registrar_clique(text, text, text, text, text, text) from public;
grant execute on function public.registrar_clique(text, text, text, text, text, text) to anon, authenticated;

-- Resumo para abrir no Table Editor do Supabase (fica invisível para quem acessa pelo site)
create or replace view public.cliques_resumo with (security_invoker = true) as
select (criado_em at time zone 'America/Sao_Paulo')::date as dia,
       site, evento, alvo, origem, count(*) as quantidade
  from public.site_cliques
 group by 1, 2, 3, 4, 5
 order by 1 desc, 6 desc;
revoke all on public.cliques_resumo from anon, authenticated;
