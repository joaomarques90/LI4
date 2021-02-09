USE iqueue;


/*
CALL create_servico("Talho dos Amores", 	  "Talho",             "08:00:00", "20:00:00", 41.5450103, -8.4020387, TRUE);
CALL create_servico("Talho dos Amores 2", 	  "Talho",             "08:00:00", "20:00:00", 41.5450103, -8.4020387, TRUE);
CALL create_servico("Pingo Amargo", 		  "Supermercado",      "08:00:00", "20:00:00", 41.5450103, -8.4020387, TRUE);
CALL create_servico("Ilhas", 				  "Supermercado",      "08:00:00", "20:00:00", 41.5450103, -8.4020387, TRUE);
CALL create_servico("Maxi Preco", 			  "Supermercado", 	   "08:00:00", "20:00:00", 41.5450103, -8.4020387, TRUE);
CALL create_servico("Luix Courgete",		  "Mercearia", 		   "10:00:00", "15:00:00", 41.5450103, -8.4020387, FALSE);
CALL create_servico("Vai ir",           	  "Transportes",       "08:00:00", "21:00:00", 41.5450103, -8.4020387, TRUE);
CALL create_servico("Tiago dos Jolhos", 	  "Take Away", 		   "11:00:00", "20:00:00", 41.5450103, -8.4020387, TRUE);
CALL create_servico("Bruno Calhau",     	  "Enterrador",		   "12:00:00", "15:00:00", 41.5450103, -8.4020387, FALSE);
CALL create_servico("Culisses Tasujo", 	  	  "Caloeiro de maos",  "08:45:00", "10:50:00", 41.5450103, -8.4020387, TRUE);
*/
SET foreign_key_checks = 0;
-- DELETE FROM Servico;
-- DROP TABLE Servico;
TRUNCATE TABLE Servico;
-- DELETE FROM Gerente;
TRUNCATE TABLE Gerente;
-- DELETE FROM Funcionario;
TRUNCATE TABLE Funcionario;
-- DELETE FROM Utilizador;
TRUNCATE TABLE Utilizador;
-- DELETE FROM Utilizador_ServicosFavoritos;
TRUNCATE TABLE Utilizador_ServicosFavoritos;
SET foreign_key_checks = 1;


INSERT INTO `Servico` (`id`, `Estado`, `nome`, `localizacao`, `categoria`, `hora_abertura`, `hora_fecho`, `latitude`, `longitude`, `reputacao_min`) VALUES (1, 1,  'Talho dos Amores', 	'R. Ambrósio dos Santos 40, 4715-242, Braga'			, 'Talho'			, '08:00:00', '18:00:00', '41.545050', '-8.402380', 	'0');
INSERT INTO `Servico` (`id`, `Estado`, `nome`, `localizacao`, `categoria`, `hora_abertura`, `hora_fecho`, `latitude`, `longitude`, `reputacao_min`) VALUES (2, 1,  'Talho dos Amores 2', 'R. Conselheiro Lobato 502, 4705-089, Braga'			, 'Talho'			, '08:00:00', '18:00:00', '41.543010', '-8.421890', 	'0');
INSERT INTO `Servico` (`id`, `Estado`, `nome`, `localizacao`, `categoria`, `hora_abertura`, `hora_fecho`, `latitude`, `longitude`, `reputacao_min`) VALUES (3, 1,  'Pingo Amargo', 		'Av. da Liberdade 525, 4700-099, Braga'					, 'Supermercado'	, '08:00:00', '18:00:00', '41.548040', 	'-8.421180', 	'0');
INSERT INTO `Servico` (`id`, `Estado`, `nome`, `localizacao`, `categoria`, `hora_abertura`, `hora_fecho`, `latitude`, `longitude`, `reputacao_min`) VALUES (4, 1,  'Ilhas', 				'R. 25 de Abril 10 90, 4710-913, Braga'				, 'Supermercado'	, '08:00:00', '18:00:00', '41.550190', 	'-8.416600', 	'0');
INSERT INTO `Servico` (`id`, `Estado`, `nome`, `localizacao`, `categoria`, `hora_abertura`, `hora_fecho`, `latitude`, `longitude`, `reputacao_min`) VALUES (5, 1,  'Maxi Preco', 		'R. de São Victor 68, 4710-439, Braga'					, 'Supermercado'	, '08:00:00', '18:00:00', '41.552420', '-8.414360', 	'0');
INSERT INTO `Servico` (`id`, `Estado`, `nome`, `localizacao`, `categoria`, `hora_abertura`, `hora_fecho`, `latitude`, `longitude`, `reputacao_min`) VALUES (6, 1,  'Luix Courgete', 		'R. Nova de Santa Cruz 19, 4710-416, Braga'			, 'Mercearia'		, '09:00:00', '18:00:00', '41.555030', 	'-8.406400', 	'0');
INSERT INTO `Servico` (`id`, `Estado`, `nome`, `localizacao`, `categoria`, `hora_abertura`, `hora_fecho`, `latitude`, `longitude`, `reputacao_min`) VALUES (7, 1,  'Vai ir', 			'Av. Gen. Carrilho da Silva Pinto 102, 4715-244, Braga'	, 'Transportes'		, '08:00:00', '18:00:00', '41.559770', '-8.388300', 	'2.5');
INSERT INTO `Servico` (`id`, `Estado`, `nome`, `localizacao`, `categoria`, `hora_abertura`, `hora_fecho`, `latitude`, `longitude`, `reputacao_min`) VALUES (8, 1,  'Churrascos', 		'R. do Paço 1, 4710-055, Gualtar'						, 'Take Away'		, '11:00:00', '18:00:00', '41.563870', 	'-8.392780', 	'0');
INSERT INTO `Servico` (`id`, `Estado`, `nome`, `localizacao`, `categoria`, `hora_abertura`, `hora_fecho`, `latitude`, `longitude`, `reputacao_min`) VALUES (9, 0,  'Bruno Gama', 		'R. Cimo de Vila, 4830-338, Póvoa de Lanhoso'			, 'Entregador'		, '12:00:00', '15:00:00', '41.575720', 	'-8.290070', 	'0');
INSERT INTO `Servico` (`id`, `Estado`, `nome`, `localizacao`, `categoria`, `hora_abertura`, `hora_fecho`, `latitude`, `longitude`, `reputacao_min`) VALUES (10, 0, 'Calos Culisses', 	'R. da Universidade 40, 4710-057, Gualtar'				, 'Caloeiro'		, '08:45:00', '10:50:00', '41.562840', 	'-8.393300', 	'0');
-- DELETE FROM Servico;
UPDATE Servico SET email = 'talhodosamores@mail.pt'   , telefone = 253254183 WHERE id = 1;
UPDATE Servico SET email = 'talhodosamores2@mail.pt'  , telefone = 253251683 WHERE id = 2;
UPDATE Servico SET email = 'pingoamargo@mail.pt'  	  , telefone = 253213483 WHERE id = 3;
UPDATE Servico SET email = 'ilhas@mail.pt'			  , telefone = 251873524 WHERE id = 4;
UPDATE Servico SET email = 'maxipreco@mail.pt'		  , telefone = 253612363 WHERE id = 5;
UPDATE Servico SET email = 'luixcourgete@mail.pt'	  , telefone = 253115315 WHERE id = 6;
UPDATE Servico SET email = 'vairirtransportes@mail.pt', telefone = 253293153 WHERE id = 7;
UPDATE Servico SET email = 'queimachurras@mail.pt'	  , telefone = 253735215 WHERE id = 8;
UPDATE Servico SET email = 'entregasgama@mail.pt'	  , telefone = 253522560 WHERE id = 9;
UPDATE Servico SET email = 'caloscalinhos@mail.pt'	  , telefone = 253066015 WHERE id = 10;

-- DROP USER '9%'@'localhost';
-- SELECT * FROM mysql.user WHERE User LIKE 'root';
-- DELETE FROM mysql.user WHERE user LIKE '9%';
-- GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost';


CALL create_gerente(948970314, "password1",  1);
CALL create_gerente(927800064, "password2",  2);
CALL create_gerente(913104583, "password3",  3);
CALL create_gerente(955693244, "password4",  4);
CALL create_gerente(938208697, "password5",  5);
CALL create_gerente(947385750, "password6",  6);
CALL create_gerente(946026433, "password7",  7);
CALL create_gerente(929929735, "password8",  8);
CALL create_gerente(935684728, "password9",  9);
CALL create_gerente(939963390, "password10", 10);
-- DELETE FROM Gerente;

CALL create_funcionario(979265988, "password1",  1,  "funcionario1");
CALL create_funcionario(971143333, "password2",  1,  "funcionario2");
CALL create_funcionario(977754345, "password3",  2,  "funcionario3");
CALL create_funcionario(976124080, "password4",  2,  "funcionario4");
CALL create_funcionario(979327504, "password5",  3,  "funcionario5");
CALL create_funcionario(978609355, "password6",  3,  "funcionario6");
CALL create_funcionario(973829733, "password7",  4,  "funcionario7");
CALL create_funcionario(975556676, "password8",  5,  "funcionario8");
CALL create_funcionario(977884879, "password9",  6,  "funcionario9");
CALL create_funcionario(972039523, "password10", 7,  "funcionario10");
CALL create_funcionario(979892630, "password11", 8,  "funcionario11");
CALL create_funcionario(976860136, "password12", 8,  "funcionario12");
CALL create_funcionario(973504992, "password13", 9,  "funcionario13");
CALL create_funcionario(970491485, "password14", 10, "funcionario14");
CALL create_funcionario(974612211, "password15", 10, "funcionario15");

-- DELETE FROM Funcionario;

CALL create_utilizador(967292405, "password1");
CALL create_utilizador(960875837, "password2");
CALL create_utilizador(962871346, "password3");
CALL create_utilizador(956210090, "password4");
CALL create_utilizador(939171520, "password5");
CALL create_utilizador(950065761, "password6");
CALL create_utilizador(962199866, "password7");
CALL create_utilizador(949510610, "password8");
CALL create_utilizador(951158911, "password9");
CALL create_utilizador(923023650, "password10");
CALL create_utilizador(946236067, "password11");
CALL create_utilizador(957661465, "password12");
CALL create_utilizador(941288712, "password13");
CALL create_utilizador(955075592, "password14");
CALL create_utilizador(946942276, "password15");
CALL create_utilizador(928820498, "password16");
CALL create_utilizador(956858146, "password17");
CALL create_utilizador(943400137, "password18");
CALL create_utilizador(932328963, "password19");
CALL create_utilizador(945977544, "password20");
CALL create_utilizador(946767242, "password21");
CALL create_utilizador(962870898, "password22");
CALL create_utilizador(920067250, "password23");
CALL create_utilizador(941047670, "password24");
CALL create_utilizador(945308218, "password25");
CALL create_utilizador(935823327, "password26");
CALL create_utilizador(921644394, "password27");
CALL create_utilizador(959137122, "password28");
CALL create_utilizador(936832204, "password29");
CALL create_utilizador(910208149, "password30");
-- DELETE FROM Utilizador;

SET foreign_key_checks = 0;
INSERT INTO `Utilizador_ServicosFavoritos` (`Utilizador_id`, `Servico_id`) VALUES (1, 1);
INSERT INTO `Utilizador_ServicosFavoritos` (`Utilizador_id`, `Servico_id`) VALUES (2, 2);
INSERT INTO `Utilizador_ServicosFavoritos` (`Utilizador_id`, `Servico_id`) VALUES (3, 3);
INSERT INTO `Utilizador_ServicosFavoritos` (`Utilizador_id`, `Servico_id`) VALUES (4, 4);
INSERT INTO `Utilizador_ServicosFavoritos` (`Utilizador_id`, `Servico_id`) VALUES (5, 5);
INSERT INTO `Utilizador_ServicosFavoritos` (`Utilizador_id`, `Servico_id`) VALUES (6, 6);
INSERT INTO `Utilizador_ServicosFavoritos` (`Utilizador_id`, `Servico_id`) VALUES (7, 7);
INSERT INTO `Utilizador_ServicosFavoritos` (`Utilizador_id`, `Servico_id`) VALUES (8, 8);
INSERT INTO `Utilizador_ServicosFavoritos` (`Utilizador_id`, `Servico_id`) VALUES (9, 9);
INSERT INTO `Utilizador_ServicosFavoritos` (`Utilizador_id`, `Servico_id`) VALUES (10, 10);
INSERT INTO `Utilizador_ServicosFavoritos` (`Utilizador_id`, `Servico_id`) VALUES (11, 1);
INSERT INTO `Utilizador_ServicosFavoritos` (`Utilizador_id`, `Servico_id`) VALUES (12, 2);
INSERT INTO `Utilizador_ServicosFavoritos` (`Utilizador_id`, `Servico_id`) VALUES (13, 3);
INSERT INTO `Utilizador_ServicosFavoritos` (`Utilizador_id`, `Servico_id`) VALUES (14, 4);
INSERT INTO `Utilizador_ServicosFavoritos` (`Utilizador_id`, `Servico_id`) VALUES (15, 5);
INSERT INTO `Utilizador_ServicosFavoritos` (`Utilizador_id`, `Servico_id`) VALUES (16, 6);
INSERT INTO `Utilizador_ServicosFavoritos` (`Utilizador_id`, `Servico_id`) VALUES (17, 7);
INSERT INTO `Utilizador_ServicosFavoritos` (`Utilizador_id`, `Servico_id`) VALUES (18, 8);
INSERT INTO `Utilizador_ServicosFavoritos` (`Utilizador_id`, `Servico_id`) VALUES (19, 9);
INSERT INTO `Utilizador_ServicosFavoritos` (`Utilizador_id`, `Servico_id`) VALUES (20, 10);
SET foreign_key_checks = 1;
-- DELETE FROM Utilizador_ServicosFavoritos;

/*
UPDATE Servico SET email = 'email_1@mail.com', telefone = 253000001 WHERE id = 1;
UPDATE Servico SET email = 'email_2@mail.com', telefone = 253000002 WHERE id = 2;
UPDATE Servico SET email = 'email_3@mail.com', telefone = 253000003 WHERE id = 3;
UPDATE Servico SET email = 'email_4@mail.com', telefone = 253000004 WHERE id = 4;
UPDATE Servico SET email = 'email_5@mail.com', telefone = 253000005 WHERE id = 5;
UPDATE Servico SET email = 'email_6@mail.com', telefone = 253000006 WHERE id = 6;
UPDATE Servico SET email = 'email_7@mail.com', telefone = 253000007 WHERE id = 7;
UPDATE Servico SET email = 'email_8@mail.com', telefone = 253000008 WHERE id = 8;
UPDATE Servico SET email = 'email_9@mail.com', telefone = 253000009 WHERE id = 9;
UPDATE Servico SET email = 'email_10@mail.com', telefone = 253000010 WHERE id = 10;
*/
-- DELETE FROM Ticket;


-- SELECT ROUTINE_NAME AS proc_name FROM INFORMATION_SCHEMA.ROUTINES WHERE (ROUTINE_TYPE = 'PROCEDURE' AND (ROUTINE_NAME LIKE 'utilizador_%' OR ROUTINE_NAME LIKE 'estatistica_%' OR ROUTINE_NAME LIKE 'servicos_%'));
-- GRANT EXECUTE ON PROCEDURE iqueue.utilizador_hide_ticket TO '979265988'@'localhost';
-- REVOKE EXECUTE ON PROCEDURE iqueue.utilizador_hide_ticket FROM '979265988'@'localhost';

DELIMITER $$
DROP PROCEDURE IF EXISTS `dropUsers` $$
			CREATE PROCEDURE dropUsers()
			BEGIN
				DECLARE n INT DEFAULT 0;
                DECLARE i INT DEFAULT 0;
                DECLARE username VARCHAR(45);
                
                DECLARE utilizador_id_3 VARCHAR(45);

                SELECT USER() INTO utilizador_id_3;
				SELECT SUBSTRING_INDEX(utilizador_id_3, '@', 1) INTO utilizador_id_3;
                IF(utilizador_id_3 != 'grupo2') 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;
                
				DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                CREATE TEMPORARY TABLE tabela_temp engine=memory SELECT user FROM mysql.user WHERE user LIKE 'U_%' OR user LIKE 'F_%' OR user LIKE 'G_%';
				
                SELECT COUNT(*) FROM tabela_temp INTO n;
                
				SET i=0;
				WHILE i<n DO 
					SELECT user INTO username FROM tabela_temp LIMIT i,1;
                    
					set @sql = concat('DROP USER "',username,'"@"%"');
					PREPARE stmt1 FROM @sql;
					EXECUTE stmt1;
					DEALLOCATE PREPARE stmt1;
                    
					SET i = i + 1;
				END WHILE;
                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                
			END$$

-- CALL dropUsers;

CALL myeventEstatisticaRealHoraria;
/*
SET foreign_key_checks = 0;
UPDATE Ticket SET servico_id = 1,  hide_ticket = 0 WHERE funcionario_id = 1;
UPDATE Ticket SET servico_id = 1,  hide_ticket = 0 WHERE funcionario_id = 2;
UPDATE Ticket SET servico_id = 2,  hide_ticket = 0 WHERE funcionario_id = 3;
UPDATE Ticket SET servico_id = 2,  hide_ticket = 0 WHERE funcionario_id = 4;
UPDATE Ticket SET servico_id = 3,  hide_ticket = 0 WHERE funcionario_id = 5;
UPDATE Ticket SET servico_id = 3,  hide_ticket = 0 WHERE funcionario_id = 6;
UPDATE Ticket SET servico_id = 4,  hide_ticket = 0 WHERE funcionario_id = 7;
UPDATE Ticket SET servico_id = 5,  hide_ticket = 0 WHERE funcionario_id = 8;
UPDATE Ticket SET servico_id = 6,  hide_ticket = 0 WHERE funcionario_id = 9;
UPDATE Ticket SET servico_id = 7,  hide_ticket = 0 WHERE funcionario_id = 10;
UPDATE Ticket SET servico_id = 8,  hide_ticket = 0 WHERE funcionario_id = 11;
UPDATE Ticket SET servico_id = 8,  hide_ticket = 0 WHERE funcionario_id = 12;
UPDATE Ticket SET servico_id = 9,  hide_ticket = 0 WHERE funcionario_id = 13;
UPDATE Ticket SET servico_id = 10, hide_ticket = 0 WHERE funcionario_id = 14;
UPDATE Ticket SET servico_id = 10, hide_ticket = 0 WHERE funcionario_id = 15;
SET foreign_key_checks = 1;

*/
/*


CALL utilizadorUPDATE_PRIVILEGIOS(967292405); -- 1
CALL utilizadorUPDATE_PRIVILEGIOS(960875837); -- 2
CALL utilizadorUPDATE_PRIVILEGIOS(962871346); -- 3
CALL utilizadorUPDATE_PRIVILEGIOS(956210090); -- 4
CALL utilizadorUPDATE_PRIVILEGIOS(939171520); -- 5
CALL utilizadorUPDATE_PRIVILEGIOS(950065761); -- 6
CALL utilizadorUPDATE_PRIVILEGIOS(962199866); -- 7
CALL utilizadorUPDATE_PRIVILEGIOS(949510610); -- 8
CALL utilizadorUPDATE_PRIVILEGIOS(951158911); -- 9
CALL utilizadorUPDATE_PRIVILEGIOS(923023650); -- 10
CALL utilizadorUPDATE_PRIVILEGIOS(946236067); -- 11
CALL utilizadorUPDATE_PRIVILEGIOS(957661465); -- 12
CALL utilizadorUPDATE_PRIVILEGIOS(941288712); -- 13
CALL utilizadorUPDATE_PRIVILEGIOS(955075592); -- 14
CALL utilizadorUPDATE_PRIVILEGIOS(946942276); -- 15
CALL utilizadorUPDATE_PRIVILEGIOS(928820498); -- 16
CALL utilizadorUPDATE_PRIVILEGIOS(956858146); -- 17
CALL utilizadorUPDATE_PRIVILEGIOS(943400137); -- 18
CALL utilizadorUPDATE_PRIVILEGIOS(932328963); -- 19
CALL utilizadorUPDATE_PRIVILEGIOS(945977544); -- 20
CALL utilizadorUPDATE_PRIVILEGIOS(946767242); -- 21
CALL utilizadorUPDATE_PRIVILEGIOS(962870898); -- 22
CALL utilizadorUPDATE_PRIVILEGIOS(920067250); -- 23
CALL utilizadorUPDATE_PRIVILEGIOS(941047670); -- 24
CALL utilizadorUPDATE_PRIVILEGIOS(945308218); -- 25
CALL utilizadorUPDATE_PRIVILEGIOS(935823327); -- 26
CALL utilizadorUPDATE_PRIVILEGIOS(921644394); -- 27
CALL utilizadorUPDATE_PRIVILEGIOS(959137122); -- 28
CALL utilizadorUPDATE_PRIVILEGIOS(936832204); -- 29
CALL utilizadorUPDATE_PRIVILEGIOS(910208149); -- 30

CALL gerenteUPDATE_PRIVILEGIOS(948970314); -- 1
CALL gerenteUPDATE_PRIVILEGIOS(927800064); -- 2
CALL gerenteUPDATE_PRIVILEGIOS(913104583); -- 3
CALL gerenteUPDATE_PRIVILEGIOS(955693244); -- 4
CALL gerenteUPDATE_PRIVILEGIOS(938208697); -- 5
CALL gerenteUPDATE_PRIVILEGIOS(947385750); -- 6
CALL gerenteUPDATE_PRIVILEGIOS(946026433); -- 7
CALL gerenteUPDATE_PRIVILEGIOS(929929735); -- 8
CALL gerenteUPDATE_PRIVILEGIOS(935684728); -- 9
CALL gerenteUPDATE_PRIVILEGIOS(939963390); -- 10

CALL funcionarioUPDATE_PRIVILEGIOS(979265988); -- 1 
CALL funcionarioUPDATE_PRIVILEGIOS(971143333); -- 2 
CALL funcionarioUPDATE_PRIVILEGIOS(977754345); -- 3 
CALL funcionarioUPDATE_PRIVILEGIOS(976124080); -- 4 
CALL funcionarioUPDATE_PRIVILEGIOS(979327504); -- 5  
CALL funcionarioUPDATE_PRIVILEGIOS(978609355); -- 6 
CALL funcionarioUPDATE_PRIVILEGIOS(973829733); -- 7 
CALL funcionarioUPDATE_PRIVILEGIOS(975556676); -- 8 
CALL funcionarioUPDATE_PRIVILEGIOS(977884879); -- 9 
CALL funcionarioUPDATE_PRIVILEGIOS(972039523); -- 10 
CALL funcionarioUPDATE_PRIVILEGIOS(979892630); -- 11 
CALL funcionarioUPDATE_PRIVILEGIOS(976860136); -- 12 
CALL funcionarioUPDATE_PRIVILEGIOS(973504992); -- 13 
CALL funcionarioUPDATE_PRIVILEGIOS(970491485); -- 14 
CALL funcionarioUPDATE_PRIVILEGIOS(974612211); -- 15 

GRANT EXECUTE ON PROCEDURE iqueue.create_utilizador TO 'guestDB'@'%';
GRANT EXECUTE ON PROCEDURE iqueue.user_exists TO 'guestDB'@'%';

FLUSH PRIVILEGES;
*/

SELECT *, CONVERT(AES_DECRYPT(pass,'UMinho2020Grupo2') USING utf8) AS password FROM Utilizador;
SELECT *, CONVERT(AES_DECRYPT(pass,'UMinho2020Grupo2') USING utf8) AS password FROM Funcionario;
SELECT *, CONVERT(AES_DECRYPT(pass,'UMinho2020Grupo2') USING utf8) AS password FROM Gerente;
