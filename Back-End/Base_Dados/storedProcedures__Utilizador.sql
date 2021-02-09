
-- ------------------------------------------------------
-- ------------------------------------------------------
-- Universidade do Minho
-- Mestrado Integrado em Engenharia Informática (MiEI)
-- Unidade Curricular de Laboratórios de Informática IV (LI4)
-- 
-- Caso de Estudo: IQueue
-- Criação de Stored Procedures, Triggers, Events, Views e Functions
--
-- Março/2020
-- Grupo 2, Turno 2
-- ------------------------------------------------------
-- ------------------------------------------------------

/* 

								***************************** INFO *****************************

	As seguintes procedures/views/functions têm em conta quem as invocou, utilizando a propria conexão-login para a identificação (sessão), 
	verificando a permissão para a sua execução e, portanto, 
    não dando hipótese de um qualquer utilizador poder obter informações ou realizar operações que não nada têm a ver consigo.
    De realçar também que essa conexão é via SLL e utilizando uma codificação hash 256 para a respectiva password.
    Logo, dando muita relevância à segurança, protecção, privacidade e performance.
    
    A password de acesso (connection to mysql db) é guardado num ficheiro criado pela db, logo inacessivel
    Visto que a password tb será guardado na tabela do Utilizador/Funcionario/Gerente mas não será utilizado
    (será utilizado a pass de conta criada na conexao para db, + eficiente e + seguro), para manter a coerência
    com o modelo será guardada mas encriptada (manter-se-ão ambas sincronizadas). 
    Dá para ter acesso à password guardada nessas tabelas (but why?) tendo que fazer AES_DECRYPT para tal
    com a string "UMinho2020Grupo2"
    
*/
		USE iqueue;
		SET @ESTADO_1 = 'Em Espera';
		SET @ESTADO_2 = 'Usado';
		SET @ESTADO_3 = 'Descartado';
		SET @ESTADO_4 = 'Inutilizado';

		DELIMITER $$


/*
****************************************************************************************************************************
****************************************************************************************************************************
										PROCEDURES »»»»»»»»» UTILIZADOR »» Tickets
****************************************************************************************************************************
****************************************************************************************************************************	
 */

  /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
                                    PROCEDURES »»»»»»»»» UTILIZADOR »» Tickets -> CREATE Automatico
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
    
            DROP PROCEDURE IF EXISTS `utilizador_create_ticket_automatico` $$
            CREATE PROCEDURE `utilizador_create_ticket_automatico`(IN _servico_id INT, IN texto VARCHAR(511))
            BEGIN               
                DECLARE utilizador_id_2 VARCHAR(45);
                DECLARE _utilizador_id INT;
                DECLARE role VARCHAR(45) DEFAULT NULL;
                DECLARE ticketNum INT;
                DECLARE contador INT;
                -- DECLARE calc INT;

                DECLARE customException CONDITION FOR SQLSTATE '45000';
                DECLARE EXIT HANDLER FOR customException 
                BEGIN
                    ROLLBACK;
                    RESIGNAL;
                END;
                DECLARE EXIT HANDLER FOR SQLEXCEPTION
                BEGIN
                    ROLLBACK;
                    RESIGNAL;
                    -- RESIGNAL SET MESSAGE_TEXT = 'An SQLEXCEPTION has occurred, operation rollbacked and the stored procedure was terminated';
                END;
                 DECLARE EXIT HANDLER FOR SQLWARNING 
                BEGIN
                    ROLLBACK;
                    RESIGNAL;
                    -- RESIGNAL SET MESSAGE_TEXT = 'An SQLWARNING has occurred, operation rollbacked and the stored procedure was terminated';
                END;
                 DECLARE EXIT HANDLER FOR NOT FOUND
                BEGIN
                    ROLLBACK;
                    RESIGNAL;
                    -- RESIGNAL SET MESSAGE_TEXT = 'An NOT FOUND has occurred, operation rollbacked and the stored procedure was terminated';
                END;
                
                
                /* Camada extra de segurança - garante que não deixa criar tickets para outros utilizadores que não o próprio
                    » protege os dados/servidor se a máquina-cliente for atacada
            
                Exemplo -> o backend/frontend foi atacado/alterado, enviando um utilizador_id/telefone diferente da conexão como argumento da procedure 
                    Solução -> remover esse argumento, trabalhando sobre a conexão em si para identificar o remetente (que é em SSL e codificação hash 256 para password)
                
                Nota - não impede de o utilizador ou atacante de invocar várias vezes a procedure
                    Solução - Apenas podemos limitar o nº de tickets_em_espera/hora
                */
                SELECT USER() INTO utilizador_id_2;
                SELECT SUBSTRING_INDEX(utilizador_id_2, '@', 1) INTO utilizador_id_2;
                SELECT SUBSTRING_INDEX(utilizador_id_2, '_', 1) INTO role;
                SELECT SUBSTR(utilizador_id_2, 3, 20) INTO utilizador_id_2;
                
                IF(role IS NULL OR role != 'U') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;

                SELECT MAX(id) INTO _utilizador_id FROM Utilizador WHERE nr_telemovel = utilizador_id_2;

                SET ticketNum = -1;


                SELECT Count(T.id) INTO contador
                    FROM Ticket T
                    WHERE utilizador_id = _utilizador_id AND servico_id = _servico_id AND estado = 'Em Espera';

                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                CREATE TEMPORARY TABLE tabela_temp engine=memory 
                SELECT U.reputacao >= S.reputacao_min AS tem_repo, 
                       S.hora_fecho >= TIME(Now()) AS antes_fecho,
                       S.hora_abertura <= TIME(Now()) AS depois_abertura , 
                       S.estado AS servico_estado
                    FROM Utilizador AS U INNER JOIN Servico AS S 
                    ON U.id = _utilizador_id AND S.id = _servico_id
                    WHERE U.id = _utilizador_id AND S.id = _servico_id;

                START TRANSACTION;

                IF(contador > 0)
                    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Blyat ter neste servico ticket activo';
                END IF;
                
                IF(SELECT tem_repo IS NULL FROM tabela_temp)
                    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Servico nao existir blyat';
                END IF;

                IF(SELECT tem_repo IS FALSE FROM tabela_temp)
                    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Blyat nao ter medalha Jukov para servico';
                END IF;
                
                IF(SELECT servico_estado IS FALSE FROM tabela_temp)
                    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Servico estar fechado blyat';
                END IF;
                
                IF(SELECT antes_fecho IS FALSE FROM tabela_temp)
                    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Blyat chegar tarde';
                END IF;
                
                IF(SELECT depois_abertura IS FALSE FROM tabela_temp)
                    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Blyat chegar cedo';
                END IF;

                SELECT COALESCE(MAX(nr_acesso)+1, 1) INTO ticketNum 
                    FROM Ticket T 
                    WHERE (T.servico_id = _servico_id AND DATE(T.data) = DATE(NOW()));

                INSERT INTO Ticket (utilizador_id, servico_id, nr_acesso, data, estado, observacoes)
                       VALUES (_utilizador_id, _servico_id, ticketNum, NOW(), 'Em Espera', texto);

                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                
                IF (ticketNum = 1) THEN UPDATE Servico SET ticket_atual = 1 WHERE id = _servico_id; 
                END IF;

                -- SELECT ticketNum AS nr_acesso;
                SELECT T.*, S.nome, S.ticket_atual 
                FROM Ticket AS T INNER JOIN Servico AS S
                    ON T.servico_id = S.id
                    WHERE 
                        T.utilizador_id = _utilizador_id AND 
                        S.id = _servico_id 
                    ORDER BY id DESC 
                    LIMIT 1;

                COMMIT;
            END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`create_ticket_automatico` TO 'utilizador';
            -- FLUSH PRIVILEGES;

  /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» UTILIZADOR »» Tickets -> CREATE
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
		DELIMITER $$
		
			DROP PROCEDURE IF EXISTS `utilizador_create_ticket` $$
			CREATE PROCEDURE `utilizador_create_ticket`( IN _servico_id INT)
			BEGIN               
				DECLARE utilizador_id_2 VARCHAR(45);
                DECLARE _utilizador_id INT;
                DECLARE role VARCHAR(45) DEFAULT NULL;
                DECLARE ticketNum INT;
                DECLARE contador INT;
                -- DECLARE calc INT;

                DECLARE customException CONDITION FOR SQLSTATE '45000';
				DECLARE EXIT HANDLER FOR customException 
				BEGIN
				    ROLLBACK;
				    RESIGNAL;
				END;
                DECLARE EXIT HANDLER FOR SQLEXCEPTION
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLEXCEPTION has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR SQLWARNING 
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLWARNING has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR NOT FOUND
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An NOT FOUND has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                
                
            	/* Camada extra de segurança - garante que não deixa criar tickets para outros utilizadores que não o próprio
					» protege os dados/servidor se a máquina-cliente for atacada
            
				Exemplo -> o backend/frontend foi atacado/alterado, enviando um utilizador_id/telefone diferente da conexão como argumento da procedure 
					Solução -> remover esse argumento, trabalhando sobre a conexão em si para identificar o remetente (que é em SSL e codificação hash 256 para password)
                
                Nota - não impede de o utilizador ou atacante de invocar várias vezes a procedure
					Solução - Apenas podemos limitar o nº de tickets_em_espera/hora
                */
				SELECT USER() INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '@', 1) INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '_', 1) INTO role;
				SELECT SUBSTR(utilizador_id_2, 3, 20) INTO utilizador_id_2;
                
                IF(role IS NULL OR role != 'U') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

                SELECT MAX(id) INTO _utilizador_id FROM Utilizador WHERE nr_telemovel = utilizador_id_2;

                SET ticketNum = -1;


				SELECT Count(T.id) INTO contador
				    FROM Ticket T
                	WHERE utilizador_id = _utilizador_id AND servico_id = _servico_id AND estado = 'Em Espera';

                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                CREATE TEMPORARY TABLE tabela_temp engine=memory 
                SELECT U.reputacao >= S.reputacao_min AS tem_repo, 
                       S.hora_fecho >= TIME(Now()) AS antes_fecho,
					   S.hora_abertura <= TIME(Now()) AS depois_abertura , 
                       S.estado AS servico_estado
				    FROM Utilizador AS U INNER JOIN Servico AS S 
                    ON U.id = _utilizador_id AND S.id = _servico_id
                	WHERE U.id = _utilizador_id AND S.id = _servico_id;

                START TRANSACTION;

                IF(contador > 0)
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Blyat ter neste servico ticket activo';
				END IF;
                
				IF(SELECT tem_repo IS NULL FROM tabela_temp)
					THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Servico nao existir blyat';
				END IF;

                IF(SELECT tem_repo IS FALSE FROM tabela_temp)
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Blyat nao ter medalha Jukov para servico';
				END IF;
                
				IF(SELECT servico_estado IS FALSE FROM tabela_temp)
					THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Servico estar fechado blyat';
				END IF;
                
				IF(SELECT antes_fecho IS FALSE FROM tabela_temp)
					THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Blyat chegar tarde';
				END IF;
                
				IF(SELECT depois_abertura IS FALSE FROM tabela_temp)
					THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Blyat chegar cedo';
				END IF;

				SELECT COALESCE(MAX(nr_acesso)+1, 1) INTO ticketNum 
					FROM Ticket T 
                    WHERE (T.servico_id = _servico_id AND DATE(T.data) = DATE(NOW()));

				INSERT INTO Ticket (utilizador_id, servico_id, nr_acesso, data, estado)
					   VALUES (_utilizador_id, _servico_id, ticketNum, NOW(), 'Em Espera');

				DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                
                IF (ticketNum = 1) THEN UPDATE Servico SET ticket_atual = 1 WHERE id = _servico_id; 
                END IF;

                -- SELECT ticketNum AS nr_acesso;
                SELECT T.*, S.nome, S.ticket_atual 
                FROM Ticket AS T INNER JOIN Servico AS S
                	ON T.servico_id = S.id
                	WHERE 
                		T.utilizador_id = _utilizador_id AND 
                		S.id = _servico_id 
                	ORDER BY id DESC 
                	LIMIT 1;

				COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`create_ticket` TO 'utilizador';
            -- FLUSH PRIVILEGES;

/* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» UTILIZADOR »» Tickets -> DESCARTADO
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
	DELIMITER $$
			DROP PROCEDURE IF EXISTS `utilizador_ticket_descartado` $$
			CREATE PROCEDURE `utilizador_ticket_descartado`(ticket_id INT)
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE utilizador_id_2 VARCHAR(45);
                DECLARE _utilizador_id INT;
                DECLARE role VARCHAR(45) DEFAULT NULL;

                DECLARE customException CONDITION FOR SQLSTATE '45000';
				DECLARE EXIT HANDLER FOR customException 
				BEGIN
				    ROLLBACK;
				    RESIGNAL;
				END;
                DECLARE EXIT HANDLER FOR SQLEXCEPTION
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLEXCEPTION has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR SQLWARNING 
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLWARNING has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR NOT FOUND
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An NOT FOUND has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                
                START TRANSACTION;
                
				SELECT USER() INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '@', 1) INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '_', 1) INTO role;
				SELECT SUBSTR(utilizador_id_2, 3, 20) INTO utilizador_id_2;
                IF(role IS NULL OR role != 'U') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

                SELECT MAX(id) INTO _utilizador_id FROM Utilizador WHERE nr_telemovel = utilizador_id_2;

                IF(SELECT T.utilizador_id != _utilizador_id FROM Ticket AS T WHERE id = ticket_id) 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'GULAG! Ticket nao ser teu blyat!';
				END IF;
				IF(SELECT T.estado != 'Em Espera' FROM Ticket AS T WHERE id = ticket_id) 
					THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nao poder ticket descartar, blyat';
				END IF;


                UPDATE Ticket AS Ti
					SET estado = 'Descartado' , 
						tempo_espera = SUBTIME(TIME(NOW()), tempo_espera)
					WHERE (Ti.id = ticket_id AND Ti.estado = 'Em Espera');

				COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`ticket_descartado` TO 'utilizador';
            -- FLUSH PRIVILEGES;
 
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» UTILIZADOR »» Tickets -> HIDE
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/

			DROP PROCEDURE IF EXISTS `utilizador_hide_ticket` $$
			CREATE PROCEDURE `utilizador_hide_ticket`(ticket_id INT, hide_value BOOLEAN)
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE utilizador_id_2 VARCHAR(45);
                DECLARE _utilizador_id INT;
                DECLARE role VARCHAR(45) DEFAULT NULL;

                DECLARE customException CONDITION FOR SQLSTATE '45000';
				DECLARE EXIT HANDLER FOR customException 
				BEGIN
				    ROLLBACK;
				    RESIGNAL;
				END;
                DECLARE EXIT HANDLER FOR SQLEXCEPTION
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLEXCEPTION has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR SQLWARNING 
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLWARNING has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR NOT FOUND
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An NOT FOUND has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                
                START TRANSACTION;
                
				SELECT USER() INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '@', 1) INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '_', 1) INTO role;
				SELECT SUBSTR(utilizador_id_2, 3, 20) INTO utilizador_id_2;
                IF(role IS NULL OR role != 'U') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

                SELECT MAX(id) INTO _utilizador_id FROM Utilizador WHERE nr_telemovel = utilizador_id_2;

                IF(SELECT T.utilizador_id != _utilizador_id FROM Ticket AS T WHERE id = ticket_id) 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'GULAG! Ticket nao ser teu blyat!';
				END IF;

                UPDATE TICKET SET hide_ticket = hide_value WHERE utilizador_id = _utilizador_id AND id = ticket_id;

                COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`hide_ticket` TO 'utilizador';
            -- FLUSH PRIVILEGES;
            
/* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» UTILIZADOR »» Tickets -> GET (LAST 30 DAYS)
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
			DELIMITER $$
            -- ULTIMOS 30 DIAS
			DROP PROCEDURE IF EXISTS `utilizador_get_tickets` $$
			CREATE PROCEDURE `utilizador_get_tickets`()
			BEGIN      
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE utilizador_id_2 VARCHAR(45);
                DECLARE _utilizador_id INT;
                DECLARE role VARCHAR(45) DEFAULT NULL;

                DECLARE customException CONDITION FOR SQLSTATE '45000';
				DECLARE EXIT HANDLER FOR customException 
				BEGIN
				    ROLLBACK;
				    RESIGNAL;
				END;
                DECLARE EXIT HANDLER FOR SQLEXCEPTION
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLEXCEPTION has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR SQLWARNING 
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLWARNING has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR NOT FOUND
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An NOT FOUND has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                
                START TRANSACTION;
                
				SELECT USER() INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '@', 1) INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '_', 1) INTO role;
				SELECT SUBSTR(utilizador_id_2, 3, 20) INTO utilizador_id_2;
                IF(role IS NULL OR role != 'U') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

                SELECT MAX(id) INTO _utilizador_id FROM Utilizador WHERE nr_telemovel = utilizador_id_2;


				SELECT T.*, S.nome, S.ticket_atual 
					FROM Ticket AS T INNER JOIN Servico AS S 
					ON T.servico_id = S.id
						WHERE 
							T.utilizador_id = _utilizador_id AND 
                            T.hide_ticket = false AND 
                            T.estado = 'Em Espera' AND
                            T.data >= (CURDATE() - INTERVAL 30 DAY) AND
                            T.servico_id = S.id
						ORDER BY id ASC;

				COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`get_tickets_utilizador` TO 'utilizador';
            -- FLUSH PRIVILEGES;
            
 /*
****************************************************************************************************************************
****************************************************************************************************************************
										PROCEDURES »»»»»»»»» UTILIZADOR »» ServicoFavorito
****************************************************************************************************************************
****************************************************************************************************************************	
 */

   /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» UTILIZADOR »» ServicoFavorito -> EXIST
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
	DELIMITER $$
			 DROP PROCEDURE IF EXISTS `utilizador_exist_servico_favorito` $$
             CREATE PROCEDURE `utilizador_exist_servico_favorito`(_servico_id INT)
             BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE utilizador_id_2 VARCHAR(45);
                DECLARE _utilizador_id INT;
                DECLARE role VARCHAR(45) DEFAULT NULL;

                DECLARE customException CONDITION FOR SQLSTATE '45000';
				DECLARE EXIT HANDLER FOR customException 
				BEGIN
				    ROLLBACK;
				    RESIGNAL;
				END;
                DECLARE EXIT HANDLER FOR SQLEXCEPTION
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLEXCEPTION has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR SQLWARNING 
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLWARNING has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR NOT FOUND
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An NOT FOUND has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                
				SELECT USER() INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '@', 1) INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '_', 1) INTO role;
				SELECT SUBSTR(utilizador_id_2, 3, 20) INTO utilizador_id_2;
                IF(role IS NULL OR role != 'U') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

                SELECT MAX(id) INTO _utilizador_id FROM Utilizador WHERE nr_telemovel = utilizador_id_2;

                IF(SELECT id IS NULL FROM Servico WHERE id = _servico_id) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Servico nao existir blyat';
				END IF;

                START TRANSACTION;
				
				SELECT servico_id FROM Utilizador_ServicosFavoritos WHERE utilizador_id = _utilizador_id AND servico_id = _servico_id;
				
				COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`exist_servico_favorito` TO 'utilizador';
            -- FLUSH PRIVILEGES;

  /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» UTILIZADOR »» ServicoFavorito -> ADD
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
	DELIMITER $$
			 DROP PROCEDURE IF EXISTS `utilizador_add_servico_favorito` $$
             CREATE PROCEDURE `utilizador_add_servico_favorito`(_servico_id INT)
             BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE utilizador_id_2 VARCHAR(45);
                DECLARE _utilizador_id INT;
                DECLARE role VARCHAR(45) DEFAULT NULL;

                DECLARE customException CONDITION FOR SQLSTATE '45000';
				DECLARE EXIT HANDLER FOR customException 
				BEGIN
				    ROLLBACK;
				    RESIGNAL;
				END;
                DECLARE EXIT HANDLER FOR SQLEXCEPTION
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLEXCEPTION has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR SQLWARNING 
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLWARNING has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR NOT FOUND
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An NOT FOUND has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                
				SELECT USER() INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '@', 1) INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '_', 1) INTO role;
				SELECT SUBSTR(utilizador_id_2, 3, 20) INTO utilizador_id_2;
                IF(role IS NULL OR role != 'U') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

                SELECT MAX(id) INTO _utilizador_id FROM Utilizador WHERE nr_telemovel = utilizador_id_2;

                IF(SELECT id IS NULL FROM Servico WHERE id = _servico_id) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Servico nao existir blyat';
				END IF;

				IF(SELECT servico_id FROM Utilizador_ServicosFavoritos WHERE utilizador_id = _utilizador_id AND servico_id = _servico_id) 
					THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ja ter servico favorito blyat, diminuir vodka';
				END IF;
                
                START TRANSACTION;
				
				INSERT INTO Utilizador_ServicosFavoritos (Utilizador_id, Servico_id) VALUES (_utilizador_id, _servico_id);
                
				COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`add_servico_favorito` TO 'utilizador';
            -- FLUSH PRIVILEGES;


  /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» UTILIZADOR »» ServicoFavorito -> REMOVE
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
	DELIMITER $$
			 DROP PROCEDURE IF EXISTS `utilizador_remove_servico_favorito` $$
             CREATE PROCEDURE `utilizador_remove_servico_favorito`(_servico_id INT)
             BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE utilizador_id_2 VARCHAR(45);
                DECLARE _utilizador_id INT;
                DECLARE role VARCHAR(45) DEFAULT NULL;

                DECLARE customException CONDITION FOR SQLSTATE '45000';
				DECLARE EXIT HANDLER FOR customException 
				BEGIN
				    ROLLBACK;
				    RESIGNAL;
				END;
                DECLARE EXIT HANDLER FOR SQLEXCEPTION
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLEXCEPTION has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR SQLWARNING 
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLWARNING has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR NOT FOUND
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An NOT FOUND has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                
				SELECT USER() INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '@', 1) INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '_', 1) INTO role;
				SELECT SUBSTR(utilizador_id_2, 3, 20) INTO utilizador_id_2;
                IF(role IS NULL OR role != 'U') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

                SELECT MAX(id) INTO _utilizador_id FROM Utilizador WHERE nr_telemovel = utilizador_id_2;

                IF(SELECT id IS NULL FROM Servico WHERE id = _servico_id) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Servico nao existir blyat';
				END IF;

				IF(SELECT servico_id IS NULL FROM Utilizador_ServicosFavoritos WHERE utilizador_id = _utilizador_id AND servico_id = _servico_id) 
					THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nao ter esse servico favorito blyat, diminuir vodka';
				END IF;
                
                START TRANSACTION;
				
				DELETE FROM Utilizador_ServicosFavoritos WHERE Utilizador_id = _utilizador_id AND Servico_id = _servico_id;
                
				COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`remove_servico_favorito` TO 'utilizador';
            -- FLUSH PRIVILEGES;

  /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» UTILIZADOR »» ServicoFavorito -> GET 
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
-- DELIMITER $$
			 DROP PROCEDURE IF EXISTS `utilizador_get_servico_favorito` $$
             CREATE PROCEDURE `utilizador_get_servico_favorito`()
             BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE utilizador_id_2 VARCHAR(45);
                DECLARE _utilizador_id INT;
                DECLARE role VARCHAR(45) DEFAULT NULL;

                DECLARE customException CONDITION FOR SQLSTATE '45000';
				DECLARE EXIT HANDLER FOR customException 
				BEGIN
				    ROLLBACK;
				    RESIGNAL;
				END;
                DECLARE EXIT HANDLER FOR SQLEXCEPTION
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLEXCEPTION has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR SQLWARNING 
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLWARNING has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR NOT FOUND
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An NOT FOUND has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                
                START TRANSACTION;
                
				SELECT USER() INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '@', 1) INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '_', 1) INTO role;
				SELECT SUBSTR(utilizador_id_2, 3, 20) INTO utilizador_id_2;
                IF(role IS NULL OR role != 'U') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

                SELECT MAX(id) INTO _utilizador_id FROM Utilizador WHERE nr_telemovel = utilizador_id_2;
                
                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
				CREATE TEMPORARY TABLE tabela_temp engine=memory 
							SELECT servico_id AS _servico_id FROM Utilizador_ServicosFavoritos WHERE Utilizador_id = _utilizador_id;
                
                SELECT * FROM Servico AS S INNER JOIN tabela_temp AS TT 
							ON S.id = TT._servico_id  
                            WHERE S.id = TT._servico_id 
                            ORDER BY S.id DESC;
			
				DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`get_servico_favorito` TO 'utilizador';
            -- FLUSH PRIVILEGES;

   /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» UTILIZADOR »» SERVICOS -> GET MORE USED LAST 30 DAYS
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/

	DELIMITER $$
			-- ULTIMOS 30 DIAS
			DROP PROCEDURE IF EXISTS `utilizador_servico_mais_usados` $$
			CREATE PROCEDURE `utilizador_servico_mais_usados`()
			BEGIN      
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE utilizador_id_2 VARCHAR(45);
                DECLARE _utilizador_id INT;
                DECLARE role VARCHAR(45) DEFAULT NULL;

                DECLARE customException CONDITION FOR SQLSTATE '45000';
				DECLARE EXIT HANDLER FOR customException 
				BEGIN
				    ROLLBACK;
				    RESIGNAL;
				END;
                DECLARE EXIT HANDLER FOR SQLEXCEPTION
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLEXCEPTION has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR SQLWARNING 
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLWARNING has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR NOT FOUND
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An NOT FOUND has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                
                START TRANSACTION;
                
				SELECT USER() INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '@', 1) INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '_', 1) INTO role;
				SELECT SUBSTR(utilizador_id_2, 3, 20) INTO utilizador_id_2;
                IF(role IS NULL OR role != 'U') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

                SELECT MAX(id) INTO _utilizador_id FROM Utilizador WHERE nr_telemovel = utilizador_id_2;

				SELECT servico_id AS Servico, COUNT(S.id) AS Total, S.nome, S.categoria, S.estado, S.hora_abertura, S.hora_fecho, S.latitude, S.longitude, S.localizacao, S.reputacao_min, S.ticket_atual, S.email, S.telefone
					FROM Ticket T INNER JOIN Servico S ON T.servico_id = S.id
						WHERE 
							T.servico_id = S.id AND
							T.utilizador_id = _utilizador_id AND 
                            (T.data BETWEEN (CURDATE() - INTERVAL 30 DAY) AND CURDATE()) 
						GROUP BY T.servico_id
						ORDER BY COUNT(S.id) DESC;
				COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`servico_mais_usados` TO 'utilizador';
            -- FLUSH PRIVILEGES;


  /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» UTILIZADOR »» Tickets -> utilizador_anual
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
	DELIMITER $$
			-- apenas Gerente e Funcionario
			DROP PROCEDURE IF EXISTS `utilizador_tickets_anual` $$
			CREATE PROCEDURE `utilizador_tickets_anual`()
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE utilizador_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _utilizador_id INT;
				DECLARE role VARCHAR(45) DEFAULT NULL;

				DECLARE customException CONDITION FOR SQLSTATE '45000';
				DECLARE EXIT HANDLER FOR customException 
				BEGIN
				    ROLLBACK;
				    RESIGNAL;
				END;
                DECLARE EXIT HANDLER FOR SQLEXCEPTION
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLEXCEPTION has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR SQLWARNING 
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLWARNING has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR NOT FOUND
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An NOT FOUND has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                
                START TRANSACTION;
                
                -- id: connection grabber
				SELECT USER() INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '@', 1) INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '_', 1) INTO role;
				SELECT SUBSTR(utilizador_id_2, 3, 20) INTO utilizador_id_2;
				IF(role IS NULL OR role != 'U') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;


				SELECT MAX(id) INTO _utilizador_id FROM Utilizador WHERE nr_telemovel = utilizador_id_2;
				
				SELECT T.*, S.nome, S.ticket_atual 
				FROM Ticket AS T INNER JOIN Servico AS S
					ON T.servico_id = S.id
            		WHERE T.utilizador_id = _utilizador_id AND 
						  (T.estado != 'Em Espera' AND T.estado != 'Descartado') AND
            		  	  T.data >=  (CURDATE() - INTERVAL 1 YEAR) AND
            		  	  T.servico_id = S.id
            		ORDER BY data DESC;


                COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`utilizador_tickets_anual` TO 'utilizador';
            -- FLUSH PRIVILEGES;
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» UTILIZADOR »» Tickets -> utilizador_mensal
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
			-- apenas Gerente e Funcionario
			DROP PROCEDURE IF EXISTS `utilizador_tickets_mensal` $$
			CREATE PROCEDURE `utilizador_tickets_mensal`()
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE utilizador_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _utilizador_id INT;
				DECLARE role VARCHAR(45) DEFAULT NULL;
                
                DECLARE customException CONDITION FOR SQLSTATE '45000';
				DECLARE EXIT HANDLER FOR customException 
				BEGIN
				    ROLLBACK;
				    RESIGNAL;
				END;
                DECLARE EXIT HANDLER FOR SQLEXCEPTION
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLEXCEPTION has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR SQLWARNING 
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLWARNING has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR NOT FOUND
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An NOT FOUND has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                
                START TRANSACTION;

                -- id: connection grabber
				SELECT USER() INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '@', 1) INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '_', 1) INTO role;
				SELECT SUBSTR(utilizador_id_2, 3, 20) INTO utilizador_id_2;
				IF(role IS NULL OR role != 'U') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

				SELECT MAX(id) INTO _utilizador_id FROM Utilizador WHERE nr_telemovel = utilizador_id_2;
				
				SELECT T.*, S.nome, S.ticket_atual 
				FROM Ticket AS T INNER JOIN Servico AS S
					ON T.servico_id = S.id
            		WHERE T.utilizador_id = _utilizador_id AND 
						  (T.estado != 'Em Espera' AND T.estado != 'Descartado') AND
            		  	  T.data >=  (CURDATE() - INTERVAL 1 MONTH) AND
            		  	  T.servico_id = S.id
            		ORDER BY data DESC;

                COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`utilizador_tickets_mensal` TO 'utilizador';
            -- FLUSH PRIVILEGES;
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» UTILIZADOR »» Tickets -> utilizador_semanal
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/

			-- apenas Gerente e Funcionario
			DROP PROCEDURE IF EXISTS `utilizador_tickets_semanal` $$
			CREATE PROCEDURE `utilizador_tickets_semanal`()
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE utilizador_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _utilizador_id INT;
				DECLARE role VARCHAR(45) DEFAULT NULL;

				DECLARE customException CONDITION FOR SQLSTATE '45000';
				DECLARE EXIT HANDLER FOR customException 
				BEGIN
				    ROLLBACK;
				    RESIGNAL;
				END;
                DECLARE EXIT HANDLER FOR SQLEXCEPTION
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLEXCEPTION has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR SQLWARNING 
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLWARNING has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR NOT FOUND
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An NOT FOUND has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                
                START TRANSACTION;
                
                -- id: connection grabber
				SELECT USER() INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '@', 1) INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '_', 1) INTO role;
				SELECT SUBSTR(utilizador_id_2, 3, 20) INTO utilizador_id_2;
				IF(role IS NULL OR role != 'U') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

				SELECT MAX(id) INTO _utilizador_id FROM Utilizador WHERE nr_telemovel = utilizador_id_2;
				
				SELECT T.*, S.nome, S.ticket_atual 
				FROM Ticket AS T INNER JOIN Servico AS S
					ON T.servico_id = S.id
            		WHERE T.utilizador_id = _utilizador_id AND 
						  (T.estado != 'Em Espera' AND T.estado != 'Descartado') AND
            		  	  T.data >=  (CURDATE() - INTERVAL 1 WEEK) AND
            		  	  T.servico_id = S.id
            		ORDER BY data DESC;

                COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`utilizador_tickets_semanal` TO 'utilizador';
            -- FLUSH PRIVILEGES;

 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» UTILIZADOR »» Tickets -> utilizador_dia
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
			-- apenas Gerente e Funcionario
			DROP PROCEDURE IF EXISTS `utilizador_tickets_dia` $$
			CREATE PROCEDURE `utilizador_tickets_dia`()
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE utilizador_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _utilizador_id INT;
				DECLARE role VARCHAR(45) DEFAULT NULL;
                
                DECLARE customException CONDITION FOR SQLSTATE '45000';
				DECLARE EXIT HANDLER FOR customException 
				BEGIN
				    ROLLBACK;
				    RESIGNAL;
				END;
                DECLARE EXIT HANDLER FOR SQLEXCEPTION
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLEXCEPTION has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR SQLWARNING 
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLWARNING has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR NOT FOUND
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An NOT FOUND has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                
                START TRANSACTION;

                -- id: connection grabber
				SELECT USER() INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '@', 1) INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '_', 1) INTO role;
				SELECT SUBSTR(utilizador_id_2, 3, 20) INTO utilizador_id_2;
				IF(role IS NULL OR role != 'U') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;


				SELECT MAX(id) INTO _utilizador_id FROM Utilizador WHERE nr_telemovel = utilizador_id_2;
				
				SELECT T.*, S.nome, S.ticket_atual 
				FROM Ticket AS T INNER JOIN Servico AS S
					ON T.servico_id = S.id
            		WHERE T.utilizador_id = _utilizador_id AND 
						  (T.estado != 'Em Espera' AND T.estado != 'Descartado') AND
            		  	  T.data >=  (CURDATE() - INTERVAL 1 DAY) AND
            		  	  T.servico_id = S.id
            		ORDER BY data DESC;


                COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`utilizador_tickets_semanal` TO 'utilizador';
            -- FLUSH PRIVILEGES;      

 /*
****************************************************************************************************************************
****************************************************************************************************************************
										PROCEDURES »»»»»»»»» UTILIZADOR »» AlterarPassword
****************************************************************************************************************************
****************************************************************************************************************************	
							BACKEND APÓS CALL DESTA PROCEDURE >>>>>>>>>> FORÇAR LOGOUT! ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */
 			-- apenas o proprio pode chamar
			DROP PROCEDURE IF EXISTS `utilizador_alterar_password` $$
			CREATE PROCEDURE `utilizador_alterar_password`(passwd VARCHAR(45))
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE utilizador_id_2 VARCHAR(45);
                DECLARE _utilizador_id INT;
                DECLARE role VARCHAR(45) DEFAULT NULL;

                DECLARE customException CONDITION FOR SQLSTATE '45000';
				DECLARE EXIT HANDLER FOR customException 
				BEGIN
				    ROLLBACK;
				    RESIGNAL;
				END;
                DECLARE EXIT HANDLER FOR SQLEXCEPTION
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLEXCEPTION has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR SQLWARNING 
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An SQLWARNING has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR NOT FOUND
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An NOT FOUND has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                
                START TRANSACTION;
                
				SELECT USER() INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '@', 1) INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '_', 1) INTO role;
				SELECT SUBSTR(utilizador_id_2, 3, 20) INTO utilizador_id_2;
                IF(role IS NULL OR role != 'U') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

                SELECT MAX(id) INTO _utilizador_id FROM Utilizador WHERE nr_telemovel = utilizador_id_2;

                UPDATE Utilizador SET pass = AES_ENCRYPT(passwd, 'UMinho2020Grupo2') WHERE id = utilizador_id_2;

				set @sql = concat('ALTER USER "U_',utilizador_id_2,'"@"%" IDENTIFIED WITH mysql_native_password BY "',passwd,'" WITH MAX_USER_CONNECTIONS 2');
				PREPARE stmt1 FROM @sql;
				EXECUTE stmt1;
				DEALLOCATE PREPARE stmt1;
				FLUSH PRIVILEGES;

				COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`alterar_Password_User` TO 'utilizador';
            -- FLUSH PRIVILEGES;
 
 /*
****************************************************************************************************************************
****************************************************************************************************************************
										PROCEDURES »»»»»»»»» UTILIZADOR »» GRANTS
****************************************************************************************************************************
****************************************************************************************************************************	
 */
 
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» UTILIZADOR »» GRANTS -> ADD
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
			-- apenas o admin pode chamar
 			DROP PROCEDURE IF EXISTS `utilizadorUPDATE_PRIVILEGIOS` $$
			CREATE PROCEDURE `utilizadorUPDATE_PRIVILEGIOS`(`user_name` INT)
            BEGIN               
                DECLARE n INT DEFAULT 0;
				DECLARE i INT DEFAULT 0;
                DECLARE procedureName VARCHAR(45);

                DECLARE utilizador_id_3 VARCHAR(45);

				SELECT USER() INTO utilizador_id_3;
				SELECT SUBSTRING_INDEX(utilizador_id_3, '@', 1) INTO utilizador_id_3;
                IF(utilizador_id_3 != 'grupo2' AND utilizador_id_3 != 'guestDB') 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;
                
                CREATE TEMPORARY TABLE tabela_temp engine=memory SELECT ROUTINE_NAME AS proc_name FROM INFORMATION_SCHEMA.ROUTINES 
                	WHERE (ROUTINE_TYPE = 'PROCEDURE' AND (ROUTINE_NAME LIKE 'utilizador_%' OR ROUTINE_NAME LIKE 'estatistica_%' OR ROUTINE_NAME LIKE 'servicos_%'));
				
				SELECT COUNT(*) FROM tabela_temp INTO n;
                
				SET i=0;
				WHILE i<n DO 
					SELECT proc_name INTO procedureName FROM tabela_temp LIMIT i,1;
                    
					set @sql = concat('GRANT EXECUTE ON PROCEDURE iqueue.',procedureName,' TO "U_',user_name,'"@"%"');
					PREPARE stmt1 FROM @sql;
					EXECUTE stmt1;
					DEALLOCATE PREPARE stmt1;
                  
					SET i = i + 1;
				END WHILE;
                
                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                CREATE TEMPORARY TABLE tabela_temp engine=memory SELECT ROUTINE_NAME AS func_name FROM INFORMATION_SCHEMA.ROUTINES 
                	WHERE (ROUTINE_TYPE = 'FUNCTION' AND ROUTINE_NAME LIKE 'utilizador_%');

				SELECT COUNT(*) FROM tabela_temp INTO n;
                
                SET i=0;
				WHILE i<n DO 
					SELECT func_name INTO procedureName FROM tabela_temp LIMIT i,1;
                    
					set @sql = concat('GRANT EXECUTE ON FUNCTION iqueue.',procedureName,' TO "U_',user_name,'"@"%"');
					PREPARE stmt1 FROM @sql;
					EXECUTE stmt1;
					DEALLOCATE PREPARE stmt1;
                  
					SET i = i + 1;
				END WHILE;
                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                
				FLUSH PRIVILEGES;

            END $$
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» UTILIZADOR »» GRANTS -> "REMOVE" && REVOKE
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/

	DELIMITER $$
			-- apenas admin e o proprio user se pode excluir
 			DROP PROCEDURE IF EXISTS `utilizador_REMOVE` $$
			CREATE PROCEDURE `utilizador_REMOVE`()
            BEGIN
				DECLARE utilizador_id_2 VARCHAR(45);
                DECLARE n INT DEFAULT 0;
				DECLARE i INT DEFAULT 0;
                DECLARE procedureName VARCHAR(45);
                
                DECLARE utilizador_id_3 VARCHAR(45);
                DECLARE user_name VARCHAR(45);


				SELECT USER() INTO utilizador_id_3;
				SELECT SUBSTRING_INDEX(utilizador_id_3, '@', 1) INTO utilizador_id_3;
                IF(utilizador_id_3 NOT LIKE 'U_%' AND utilizador_id_3 != 'grupo2') 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;

                CREATE TEMPORARY TABLE tabela_temp engine=memory SELECT ROUTINE_NAME AS proc_name FROM INFORMATION_SCHEMA.ROUTINES 
                	WHERE (ROUTINE_TYPE = 'PROCEDURE' AND (ROUTINE_NAME LIKE 'utilizador_%' OR ROUTINE_NAME LIKE 'estatistica_%' OR ROUTINE_NAME LIKE 'servicos_%'));
				SELECT COUNT(*) FROM tabela_temp INTO n;
                
                /* Camada extra de segurança - garante que não deixa alterar permissoes que não sejam as suas */
				
				SELECT SUBSTR(utilizador_id_3, 3, 20) INTO user_name;

				SET i=0;
				WHILE i<n DO 
					SELECT proc_name INTO procedureName FROM tabela_temp LIMIT i,1;
                    
					set @sql = concat('REVOKE EXECUTE ON PROCEDURE iqueue.',procedureName,' FROM "U_',user_name,'"@"%"');
					PREPARE stmt1 FROM @sql;
					EXECUTE stmt1;
					DEALLOCATE PREPARE stmt1;
                  
					SET i = i + 1;
				END WHILE;
                
                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                CREATE TEMPORARY TABLE tabela_temp engine=memory SELECT ROUTINE_NAME AS func_name FROM INFORMATION_SCHEMA.ROUTINES 
                	WHERE (ROUTINE_TYPE = 'FUNCTION' AND ROUTINE_NAME LIKE 'utilizador_%');
				SELECT COUNT(*) FROM tabela_temp INTO n;
                
                SET i=0;
				WHILE i<n DO 
					SELECT func_name INTO procedureName FROM tabela_temp LIMIT i,1;
                    
					set @sql = concat('REVOKE EXECUTE ON FUNCTION iqueue.',procedureName,' FROM "U_',user_name,'"@"%"');
					PREPARE stmt1 FROM @sql;
					EXECUTE stmt1;
					DEALLOCATE PREPARE stmt1;
                  
					SET i = i + 1;
				END WHILE;
                
                
				FLUSH PRIVILEGES;
    			
				set @sql = concat('DROP USER "U_',user_name,'"@"%"');
				PREPARE stmt1 FROM @sql;
				EXECUTE stmt1;
				DEALLOCATE PREPARE stmt1;
                
				DROP TEMPORARY TABLE IF EXISTS tabela_temp;

            END $$
			-- GRANT EXECUTE ON PROCEDURE `iqueue`.`utilizador_REMOVE` TO 'utilizador';
            -- FLUSH PRIVILEGES;
            
            