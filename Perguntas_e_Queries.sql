-- NOME DAS TABELAS USADAS (ambas possuem a mesma quantidade de colunas)
    -- vendas
    -- devolucao

SELECT *
FROM mvp_talles.analise_vendas_devolucoes.vendas
LIMIT 10

-- 1. Qual é o faturamento total por mês, considerando vendas descontadas das devoluções?

SELECT
    v.mes,
    sum(v.valor_da_nf) as total_vendas,
    sum(d.valor_da_nf) as total_devolucoes,
    sum(v.valor_da_nf) - SUM(d.valor_da_nf) AS faturamento_liquido
FROM mvp_talles.analise_vendas_devolucoes.vendas v
LEFT JOIN mvp_talles.analise_vendas_devolucoes.devolucao d
    ON v.cod_produto = d.cod_produto
GROUP BY v.mes
ORDER BY v.mes;

-- 2. Qual são os produtos com maior índice de devolução (%)?

WITH vendas AS (
  SELECT cod_produto, produto, SUM(quantidade) AS qtd_vendida
  FROM mvp_talles.analise_vendas_devolucoes.vendas
  GROUP BY cod_produto, produto
),
devolvido AS (
  SELECT cod_produto, SUM(quantidade) AS qtd_devolvida
  FROM mvp_talles.analise_vendas_devolucoes.devolucao
  GROUP BY cod_produto
)
SELECT
    v.cod_produto,
    v.produto,
    v.qtd_vendida,
    COALESCE(d.qtd_devolvida, 0) AS qtd_devolvida,
    (COALESCE(d.qtd_devolvida, 0) / v.qtd_vendida) * 100 AS perc_devolucao
FROM vendas v
LEFT JOIN devolvido d 
    ON v.cod_produto = d.cod_produto
ORDER BY perc_devolucao DESC;

-- 3. Qual vendedor teve o maior número de vendas líquidas (vendas-devoluções) no período?

SELECT
    v.vendedor,
    SUM(v.valor_da_nf) AS vendas,
    SUM(d.valor_da_nf) AS devolucoes,
    SUM(v.valor_da_nf) - SUM(d.valor_da_nf) AS venda_liquida
FROM mvp_talles.analise_vendas_devolucoes.vendas v
LEFT JOIN mvp_talles.analise_vendas_devolucoes.devolucao d
    ON v.cod_produto = d.cod_produto
GROUP BY v.vendedor
ORDER BY venda_liquida DESC;

-- 4. Quais lojas mais devolvem produtos e qual o valor financeiro dessas devoluções?

SELECT
    loja,
    SUM(valor_da_nf) AS valor_devolvido,
    SUM(quantidade) AS itens_devolvidos
FROM mvp_talles.analise_vendas_devolucoes.devolucao
GROUP BY loja
ORDER BY valor_devolvido DESC;

-- 5. Qual grupo  de produtos (categoria) gera mais receita líquida?

SELECT
    v.grupo,
    SUM(v.valor_da_nf) AS vendas,
    SUM(d.valor_da_nf) AS devolucoes,
    SUM(v.valor_da_nf) - SUM(d.valor_da_nf) AS receita_liquida
FROM mvp_talles.analise_vendas_devolucoes.vendas v
LEFT JOIN mvp_talles.analise_vendas_devolucoes.devolucao d
    ON v.cod_produto = d.cod_produto
GROUP BY v.grupo
ORDER BY receita_liquida DESC;

-- 6. Qual é o ticket médio dos pedidos (vendas) e o ticket médio "perdido" por devoluções?

SELECT 
    AVG(v.valor_da_nf) AS ticket_medio_venda,
    AVG(COALESCE(d.valor_da_nf,0)) AS ticket_medio_devolucao
FROM mvp_talles.analise_vendas_devolucoes.vendas v
LEFT JOIN mvp_talles.analise_vendas_devolucoes.devolucao d
    ON v.cod_produto = d.cod_produto;

-- 7. Que tipo de atendimento mais venda e qual mais devolve (B2B ou B2C)?

WITH vendas AS (
    SELECT
        atendimento,
        SUM(valor_da_nf) AS total_vendas,
        SUM(quantidade) AS itens_vendidos
    FROM mvp_talles.analise_vendas_devolucoes.vendas
    GROUP BY atendimento
),
devol AS (
    SELECT
        atendimento,
        SUM(valor_da_nf) AS total_devolucoes,
        SUM(quantidade) AS itens_devolvidos
    FROM mvp_talles.analise_vendas_devolucoes.devolucao
    GROUP BY atendimento
)

SELECT
    v.atendimento,
    v.total_vendas,
    COALESCE(d.total_devolucoes, 0) AS total_devolucoes,
    v.itens_vendidos,
    COALESCE(d.itens_devolvidos, 0) AS itens_devolvidos,
    (COALESCE(d.total_devolucoes,0) / v.total_vendas) * 100 AS percentual_devolucao
FROM vendas v
LEFT JOIN devol d 
    ON v.atendimento = d.atendimento
ORDER BY percentual_devolucao DESC;

-- 8. Qual a evolução mensal do volume de vendas versus devoluções?

SELECT
    v.mes,
    SUM(v.quantidade) AS qtd_vendido,
    SUM(d.quantidade) AS qtd_devolvido,
    SUM(v.valor_da_nf) AS vendas,
    SUM(d.valor_da_nf) AS devolucoes
FROM mvp_talles.analise_vendas_devolucoes.vendas v
LEFT JOIN mvp_talles.analise_vendas_devolucoes.devolucao d USING(cod_produto)
GROUP BY v.mes
ORDER BY v.mes;

-- 9. Quais produtos tem devoluções recorrentes acima de 2 vezes pelo mesmo cliente?

SELECT 
    atendimento,
    cod_produto,
    COUNT(*) AS qtd_devolucoes
FROM mvp_talles.analise_vendas_devolucoes.devolucao
GROUP BY atendimento, cod_produto
HAVING COUNT(*) >= 2
ORDER BY qtd_devolucoes DESC;

-- 10. Qual o impacto financeiro das devoluções sobre o faturamento total?

SELECT
    (SUM(d.valor_da_nf) / SUM(v.valor_da_nf)) * 100 AS percentual_impacto
FROM mvp_talles.analise_vendas_devolucoes.vendas v
LEFT JOIN mvp_talles.analise_vendas_devolucoes.devolucao d USING(cod_produto);
