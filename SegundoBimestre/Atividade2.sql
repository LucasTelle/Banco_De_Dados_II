CREATE DATABASE IF NOT EXISTS db_techmarket;
USE db_techmarket;

CREATE TABLE clientes (
    id_cliente INT PRIMARY KEY,
    nome VARCHAR(100),
    cidade VARCHAR(60),
    estado CHAR(2)
);

CREATE TABLE vendedores (
    id_vendedor INT PRIMARY KEY,
    nome VARCHAR(100),
    equipe VARCHAR(50)
);

CREATE TABLE produtos (
    id_produto INT PRIMARY KEY,
    descricao VARCHAR(100),
    categoria VARCHAR(50),
    preco DECIMAL(10,2)
);

CREATE TABLE pedidos (
    id_pedido INT PRIMARY KEY,
    id_cliente INT,
    id_vendedor INT,
    data_pedido DATE,
    status_pedido VARCHAR(20),
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    FOREIGN KEY (id_vendedor) REFERENCES vendedores(id_vendedor)
);

CREATE TABLE itens_pedido (
    id_item INT PRIMARY KEY,
    id_pedido INT,
    id_produto INT,
    quantidade INT,
    preco_unitario DECIMAL(10,2),
    desconto_percentual DECIMAL(5,2),
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido),
    FOREIGN KEY (id_produto) REFERENCES produtos(id_produto)
);

INSERT INTO clientes VALUES
(1,'Ana Souza','Curitiba','PR'),
(2,'Bruno Lima','Londrina','PR'),
(3,'Carla Mendes','Sao Paulo','SP'),
(4,'Daniel Rocha','Curitiba','PR'),
(5,'Eduarda Alves','Joinville','SC'),
(6,'Felipe Costa','Campinas','SP'),
(7,'Gabriela Martins','Maringa','PR'),
(8,'Henrique Dias','Florianopolis','SC');

INSERT INTO vendedores VALUES
(1,'Marcos Silva','Sul'),
(2,'Patricia Gomes','Sul'),
(3,'Ricardo Oliveira','Sudeste'),
(4,'Juliana Ferreira','Sudeste');

INSERT INTO produtos VALUES
(1,'Notebook Pro', 'Computadores',4500.00),
(2,'Mouse Gamer','Perifericos',180.00),
(3,'Teclado Mecanico','Perifericos',350.00),
(4,'Monitor 27','Monitores',1400.00),
(5,'Headset Pro','Audio',420.00),
(6,'Webcam HD','Acessorios',260.00),
(7,'SSD 1TB','Armazenamento',550.00),
(8,'Hub USB-C','Acessorios',150.00);

INSERT INTO pedidos VALUES
(101,1,1,'2026-09-01','Faturado'),
(102,2,1,'2026-09-02','Faturado'),
(103,3,3,'2026-09-03','Faturado'),
(104,4,2,'2026-09-05','Cancelado'),
(105,5,2,'2026-09-06','Faturado'),
(106,6,3,'2026-09-08','Faturado'),
(107,1,1,'2026-09-10','Faturado'),
(108,7,2,'2026-09-12','Pendente'),
(109,2,2,'2026-09-15','Faturado'),
(110,3,3,'2026-09-17','Faturado'),
(111,5,1,'2026-09-19','Faturado'),
(112,6,3,'2026-09-22','Faturado');

INSERT INTO itens_pedido VALUES
(1,101,1,1,4500,10),
(2,101,2,2,180,0),
(3,102,3,2,350,5),
(4,102,5,1,420,0),
(5,103,4,2,1400,10),
(6,103,6,1,260,0),
(7,104,1,1,4500,0),
(8,105,7,2,550,5),
(9,105,8,3,150,0),
(10,106,1,2,4500,5),
(11,106,3,1,350,0),
(12,107,4,1,1400,0),
(13,107,5,2,420,10),
(14,108,2,4,180,0),
(15,109,6,3,260,0),
(16,109,8,2,150,5),
(17,110,7,1,550,0),
(18,110,2,3,180,10),
(19,111,3,2,350,0),
(20,112,1,1,4500,15);

USE db_techmarket;

CREATE VIEW vw_vendas_detalhadas AS
SELECT
    p.id_pedido,
    p.data_pedido,
    p.status_pedido,
    c.id_cliente,
    c.nome AS cliente,
    c.cidade,
    c.estado,
    v.id_vendedor,
    v.nome AS vendedor,
    v.equipe,
    pr.id_produto,
    pr.descricao AS produto,
    pr.categoria,
    i.id_item,
    i.quantidade,
    i.preco_unitario,
    i.desconto_percentual,
    i.quantidade * i.preco_unitario AS valor_bruto,
    i.quantidade * i.preco_unitario * i.desconto_percentual / 100 AS valor_desconto,
    i.quantidade * i.preco_unitario - (i.quantidade * i.preco_unitario * i.desconto_percentual / 100) AS valor_faturado
FROM itens_pedido i
JOIN pedidos p ON i.id_pedido = p.id_pedido
JOIN clientes c ON p.id_cliente = c.id_cliente
JOIN vendedores v ON p.id_vendedor = v.id_vendedor
JOIN produtos pr ON i.id_produto = pr.id_produto
WHERE p.status_pedido = 'Faturado';

SELECT * FROM vw_vendas_detalhadas
ORDER BY valor_faturado DESC;

SELECT id_pedido, cliente, produto, valor_faturado
FROM vw_vendas_detalhadas
ORDER BY valor_faturado DESC
LIMIT 5;

SELECT id_pedido, data_pedido, cliente, estado, produto, valor_faturado
FROM vw_vendas_detalhadas
WHERE estado = 'PR'
ORDER BY data_pedido;


CREATE VIEW vw_desempenho_vendedores AS
SELECT
    v.id_vendedor,
    v.nome AS vendedor,
    v.equipe,
    COUNT(DISTINCT d.id_pedido) AS qtd_pedidos,
    IFNULL(SUM(d.quantidade), 0) AS qtd_unidades,
    IFNULL(SUM(d.valor_faturado), 0) AS faturamento
FROM vendedores v
LEFT JOIN vw_vendas_detalhadas d ON v.id_vendedor = d.id_vendedor
GROUP BY v.id_vendedor, v.nome, v.equipe;

SELECT
    vendedor,
    equipe,
    faturamento,
    qtd_pedidos,
    IF(qtd_pedidos = 0, 0, ROUND(faturamento / qtd_pedidos, 2)) AS ticket_medio
FROM vw_desempenho_vendedores
ORDER BY faturamento DESC;

SELECT
    equipe,
    SUM(faturamento) AS faturamento_total,
    SUM(qtd_pedidos) AS qtd_pedidos
FROM vw_desempenho_vendedores
GROUP BY equipe
ORDER BY faturamento_total DESC;


CREATE VIEW vw_desempenho_produtos AS
SELECT
    id_produto,
    produto,
    categoria,
    SUM(quantidade) AS qtd_unidades,
    COUNT(DISTINCT id_pedido) AS qtd_pedidos,
    SUM(valor_faturado) AS receita
FROM vw_vendas_detalhadas
GROUP BY id_produto, produto, categoria;

SELECT produto, qtd_unidades, receita
FROM vw_desempenho_produtos
ORDER BY receita DESC;

SELECT
    categoria,
    SUM(qtd_unidades) AS qtd_unidades,
    SUM(receita) AS faturamento
FROM vw_desempenho_produtos
GROUP BY categoria
HAVING SUM(receita) > 2000
ORDER BY faturamento DESC;

SELECT
    produto,
    qtd_unidades,
    receita,
    ROUND(receita / qtd_unidades, 2) AS valor_medio_unidade
FROM vw_desempenho_produtos
ORDER BY valor_medio_unidade DESC
LIMIT 3;


CREATE VIEW vw_resumo_clientes AS
SELECT
    c.id_cliente,
    c.nome AS cliente,
    c.cidade,
    c.estado,
    COUNT(DISTINCT d.id_pedido) AS qtd_pedidos,
    IFNULL(SUM(d.valor_faturado), 0) AS valor_total
FROM clientes c
LEFT JOIN vw_vendas_detalhadas d ON c.id_cliente = d.id_cliente
GROUP BY c.id_cliente, c.nome, c.cidade, c.estado;

SELECT
    cliente,
    valor_total,
    qtd_pedidos,
    IF(qtd_pedidos = 0, 0, ROUND(valor_total / qtd_pedidos, 2)) AS ticket_medio
FROM vw_resumo_clientes
ORDER BY valor_total DESC;

SELECT
    cliente,
    valor_total,
    CASE
        WHEN valor_total >= 5000 THEN 'VIP'
        WHEN valor_total > 0 THEN 'Regular'
        ELSE 'Sem compras'
    END AS grupo
FROM vw_resumo_clientes
ORDER BY valor_total DESC;

SELECT
    estado,
    SUM(valor_total) AS faturamento_total,
    COUNT(*) AS qtd_clientes,
    ROUND(SUM(valor_total) / COUNT(*), 2) AS media_por_cliente
FROM vw_resumo_clientes
GROUP BY estado
ORDER BY faturamento_total DESC;


SELECT
    equipe,
    SUM(qtd_pedidos) AS qtd_pedidos,
    SUM(faturamento) AS faturamento,
    ROUND(SUM(faturamento) / SUM(qtd_pedidos), 2) AS ticket_medio
FROM vw_desempenho_vendedores
GROUP BY equipe
ORDER BY faturamento DESC;

SELECT
    categoria,
    SUM(receita) AS faturamento,
    ROUND(SUM(receita) * 100 / (SELECT SUM(receita) FROM vw_desempenho_produtos), 2) AS percentual
FROM vw_desempenho_produtos
GROUP BY categoria
ORDER BY faturamento DESC;

SELECT
    cliente,
    estado,
    valor_total,
    ROUND(valor_total - (SELECT AVG(valor_total) FROM vw_resumo_clientes WHERE qtd_pedidos > 0), 2) AS diferenca_media
FROM vw_resumo_clientes
WHERE valor_total > (SELECT AVG(valor_total) FROM vw_resumo_clientes WHERE qtd_pedidos > 0)
ORDER BY valor_total DESC;


ALTER VIEW vw_desempenho_vendedores AS
SELECT
    v.id_vendedor,
    v.nome AS vendedor,
    v.equipe,
    COUNT(DISTINCT d.id_pedido) AS qtd_pedidos,
    IFNULL(SUM(d.quantidade), 0) AS qtd_unidades,
    IFNULL(SUM(d.valor_faturado), 0) AS faturamento,
    IFNULL(SUM(d.valor_desconto), 0) AS total_desconto
FROM vendedores v
LEFT JOIN vw_vendas_detalhadas d ON v.id_vendedor = d.id_vendedor
GROUP BY v.id_vendedor, v.nome, v.equipe;

SELECT
    vendedor,
    equipe,
    faturamento,
    total_desconto,
    qtd_pedidos,
    IF(qtd_pedidos = 0, 0, ROUND(faturamento / qtd_pedidos, 2)) AS ticket_medio
FROM vw_desempenho_vendedores
ORDER BY faturamento DESC;

SELECT
    equipe,
    SUM(faturamento) AS faturamento_total,
    SUM(qtd_pedidos) AS qtd_pedidos
FROM vw_desempenho_vendedores
GROUP BY equipe
ORDER BY faturamento_total DESC;

SELECT
    equipe,
    SUM(qtd_pedidos) AS qtd_pedidos,
    SUM(faturamento) AS faturamento,
    ROUND(SUM(faturamento) / SUM(qtd_pedidos), 2) AS ticket_medio
FROM vw_desempenho_vendedores
GROUP BY equipe
ORDER BY faturamento DESC;