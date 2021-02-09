
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
-- A55872 - JOAO MARQUES
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

		-- CREATE ROLE 'funcionario';
		DELIMITER $$
 /*
****************************************************************************************************************************
****************************************************************************************************************************
										PROCEDURES »»»»»»»»» FUNCIONARIO »» CREATE
****************************************************************************************************************************
****************************************************************************************************************************	
 */
 			-- Apenas admin (e gerente ?)
			DROP PROCEDURE IF EXISTS `create_funcionario` $$
			CREATE PROCEDURE `create_funcionario`(`user_name` INT, `passwd` VARCHAR(45), `_servico_id` INT)
			BEGIN
				DECLARE user VARCHAR(45);
				DECLARE _gerente_id INT;
                DECLARE role VARCHAR(45) DEFAULT NULL;

                SELECT USER() INTO user;
				SELECT SUBSTRING_INDEX(user, '@', 1) INTO user;
				SELECT SUBSTRING_INDEX(user, '_', 1) INTO role;

				IF(role = 'G') THEN 
					SELECT SUBSTR(user, 3, 20) INTO user;
					SELECT MAX(id) INTO _gerente_id FROM Gerente  WHERE servico_id = _servico_id AND nr_telemovel = user;
				END IF;
				

                IF(user != 'grupo2' AND _gerente_id IS NULL) 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;

				set @sql = concat('CREATE USER "F_',user_name,'"@"%" IDENTIFIED WITH mysql_native_password BY "',passwd,'" WITH MAX_USER_CONNECTIONS 2');
				PREPARE stmt1 FROM @sql;
				EXECUTE stmt1;
				DEALLOCATE PREPARE stmt1;

				CALL funcionarioUPDATE_PRIVILEGIOS(user_name);
				INSERT INTO Funcionario(nr_telemovel, pass, servico_id) VALUES (user_name, AES_ENCRYPT(passwd, 'UMinho2020Grupo2'), _servico_id);

			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`create_ticket` TO 'gerente'; -- <<<<<<<<----------------------------------------
            -- FLUSH PRIVILEGES;

 /*
****************************************************************************************************************************
****************************************************************************************************************************
										PROCEDURES »»»»»»»»» FUNCIONARIO »» CREATE (name)
****************************************************************************************************************************
****************************************************************************************************************************	
 */
 
	DELIMITER $$
 			-- Apenas admin (e gerente ?)
			DROP PROCEDURE IF EXISTS `create_funcionario_2` $$
			CREATE PROCEDURE `create_funcionario_2`(`user_name` INT, `passwd` VARCHAR(45), `_servico_id` INT, `nome` VARCHAR(255))
			BEGIN
				DECLARE user VARCHAR(45);
				DECLARE _gerente_id INT;
                DECLARE role VARCHAR(45) DEFAULT NULL;

                SELECT USER() INTO user;
				SELECT SUBSTRING_INDEX(user, '@', 1) INTO user;
				SELECT SUBSTRING_INDEX(user, '_', 1) INTO role;

				IF(role = 'G') THEN 
					SELECT SUBSTR(user, 3, 20) INTO user;
					-- SELECT user;
					SELECT MAX(id) INTO _gerente_id FROM Gerente WHERE servico_id = _servico_id AND nr_telemovel = user;
					-- SELECT _gerente_id IS NULL;
				END IF;
				

                IF(user != 'grupo2' AND _gerente_id IS NULL) 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;

				set @sql = concat('CREATE USER "F_',user_name,'"@"%" IDENTIFIED WITH mysql_native_password BY "',passwd,'" WITH MAX_USER_CONNECTIONS 2');
				PREPARE stmt1 FROM @sql;
				EXECUTE stmt1;
				DEALLOCATE PREPARE stmt1;

				CALL funcionarioUPDATE_PRIVILEGIOS(user_name);
				INSERT INTO Funcionario(nr_telemovel, pass, servico_id, nome) VALUES (user_name, AES_ENCRYPT(passwd, 'UMinho2020Grupo2'), _servico_id, nome);

			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`create_ticket` TO 'gerente'; -- <<<<<<<<----------------------------------------
            -- FLUSH PRIVILEGES;


 /*
****************************************************************************************************************************
****************************************************************************************************************************
										PROCEDURES »»»»»»»»» FUNCIONARIO »» RENAME
****************************************************************************************************************************
****************************************************************************************************************************	
 */
	DELIMITER $$
 			-- Apenas admin (e gerente ?)
			DROP PROCEDURE IF EXISTS `funcionario_rename` $$
			CREATE PROCEDURE `funcionario_rename`(`user_name` VARCHAR(255))
			BEGIN
				DECLARE user VARCHAR(45);
				DECLARE _funcionario_id INT;
				DECLARE _servico_id INT;
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

                SELECT USER() INTO user;
				SELECT SUBSTRING_INDEX(user, '@', 1) INTO user;
				SELECT SUBSTRING_INDEX(user, '_', 1) INTO role;

				IF (role = 'F') THEN 
					SELECT SUBSTR(user, 3, 20) INTO user;
					SELECT MAX(id) INTO _funcionario_id FROM Funcionario  WHERE Funcionario.nr_telemovel = user;
				END IF;
				

                IF(user != 'grupo2' AND _funcionario_id IS NULL) 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;

				UPDATE FUNCIONARIO SET nome = user_name WHERE id = _funcionario_id;

				COMMIT;

			END$$
			-- GRANT EXECUTE ON PROCEDURE `iqueue`.`rename` TO 'funcionario'; -- <<<<<<<<----------------------------------------
            -- FLUSH PRIVILEGES;

 /*
****************************************************************************************************************************
****************************************************************************************************************************
										PROCEDURES »»»»»»»»» FUNCIONARIO »» Tickets
****************************************************************************************************************************
****************************************************************************************************************************	
 */
 

 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» funcionario »» Tickets -> GET (LAST 24H)
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
	DELIMITER $$
			-- no ultimo dia
			DROP PROCEDURE IF EXISTS `funcionario_get_tickets` $$
			CREATE PROCEDURE `funcionario_get_tickets`()
			BEGIN      
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE funcionario_id_2 VARCHAR(45);
                DECLARE _funcionario_id INT;
                DECLARE _servico_id INT;
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
                
				SELECT USER() INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '@', 1) INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '_', 1) INTO role;
				SELECT SUBSTR(funcionario_id_2, 3, 20) INTO funcionario_id_2;

                IF(role IS NULL OR (role != 'F' AND role != 'G')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

                -- SELECT MAX(id) INTO _funcionario_id FROM Funcionario WHERE nr_telemovel = funcionario_id_2;
                -- SELECT servico_id INTO _servico_id FROM Funcionario WHERE id = _funcionario_id;
				
				IF(role = 'F') THEN 
					SELECT MAX(id) INTO _funcionario_id FROM Funcionario WHERE nr_telemovel = funcionario_id_2;
					SELECT servico_id INTO _servico_id FROM Funcionario WHERE id = _funcionario_id;
				ELSE /* role = 'G' */ 
					SELECT MAX(id) INTO _funcionario_id FROM Gerente WHERE nr_telemovel = funcionario_id_2;
					SELECT servico_id INTO _servico_id FROM Gerente WHERE id = _funcionario_id;
				END IF;


				SELECT * FROM Ticket 
						WHERE
							servico_id = _servico_id AND
                            estado = 'Em Espera' AND 
                            data >= (CURDATE() - INTERVAL 1 DAY)  AND
                            tempo_espera IS NULL
						ORDER BY id ASC;

				COMMIT;

			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`get_tickets_funcionario` TO 'funcionario';
            -- FLUSH PRIVILEGES;
  /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» FUNCIONARIO »» Tickets -> ATENDER
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
			DELIMITER $$
            -- apenas Gerente e Funcionario
			DROP PROCEDURE IF EXISTS `funcionario_atender_ticket` $$
			CREATE PROCEDURE `funcionario_atender_ticket`(ticketID INT)
            BEGIN                
				DECLARE funcionario_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _funcionario_id INT;
                DECLARE _servico_id INT;
                DECLARE _ticket_id INT;
                DECLARE _estado VARCHAR(45) DEFAULT NULL;
                DECLARE _tempo_espera TIME DEFAULT NULL;
                DECLARE _servico_id_Ticket INT;
                DECLARE _data DATETIME;
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
                
            	/* Camada extra de segurança - garante que não deixa criar tickets para outros utilizadores que não o próprio
					» protege os dados/servidor se a máquina-cliente for atacada
            
					Exemplo -> o backend/frontend foi atacado/alterado, enviando um utilizador_id/telefone diferente da conexão como argumento da procedure 
					Solução -> remover esse argumento, trabalhando sobre a conexão em si para identificar o remetente (que é em SSL e codificação hash 256 para password)
                
                	Nota - não impede de o utilizador ou atacante de invocar várias vezes a procedure
					Solução - Apenas podemos limitar o nº de tickets_em_espera/hora
                */
                -- id: connection grabber
				SELECT USER() INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '@', 1) INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '_', 1) INTO role;
				SELECT SUBSTR(funcionario_id_2, 3, 20) INTO funcionario_id_2;

				IF(role IS NULL OR (role != 'F' AND role != 'G')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

				IF(role = 'F') THEN 
					SELECT MAX(id) INTO _funcionario_id FROM Funcionario WHERE nr_telemovel = funcionario_id_2;
					SELECT servico_id INTO _servico_id FROM Funcionario WHERE id = _funcionario_id;
				ELSE /* role = 'G' */ 
					SELECT MAX(id) INTO _funcionario_id FROM Gerente WHERE nr_telemovel = funcionario_id_2;
					SELECT servico_id INTO _servico_id FROM Gerente WHERE id = _funcionario_id;
				END IF;
				

                -- SELECT servico_id INTO _servico_id FROM Funcionario WHERE id = funcionario_id;
                
                -- vars
                SELECT id 			INTO _ticket_id 		FROM Ticket WHERE id = ticketID;
                SELECT estado  		INTO _estado 		    FROM Ticket WHERE id = _ticket_id;
                SELECT tempo_espera INTO _tempo_espera 	    FROM Ticket WHERE id = _ticket_id;
                SELECT servico_id 	INTO _servico_id_Ticket FROM Ticket WHERE id = ticketID;
                SELECT data 	   	INTO _data 			    FROM Ticket WHERE id = ticketID;
                
                IF(_ticket_id IS NULL) 										 	 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket - ID Nao existente BD';
					ELSE IF(_estado = 'Usado') 								     THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket - Já Usado';
					ELSE IF(_estado = 'Descartado') 						     THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket - Já Descartado';
					ELSE IF(_estado = 'Inutilizado') 						     THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket - Já Inutilizado';
					ELSE IF(_servico_id_Ticket != _servico_id) 				     THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket - Servico errado';
					ELSE IF(_estado = 'Em Espera' AND _tempo_espera IS NOT NULL) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket - Em Utilizacao';
				END IF; END IF; END IF; END IF; END IF; END IF;
                
                
                -- »»»»»»»»»»»»»»»»»» em atendimento «««««««««««««««««««««««

                SELECT TIMEDIFF(NOW(), _data) AS tempo_espera;

                UPDATE Ticket 
					SET tempo_espera = TIMEDIFF(NOW(), _data) 
						WHERE id = ticketID;

				IF(role = 'F') THEN UPDATE Ticket 
					SET funcionario_id = _funcionario_id
						WHERE id = ticketID;
				ELSE /* role = 'G' */ UPDATE Ticket 
					SET gerente_id = _funcionario_id
						WHERE id = ticketID;
				END IF;
                
                COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`funcionario_atender_ticket` TO 'funcionario';
            -- FLUSH PRIVILEGES;

 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» FUNCIONARIO »» Tickets -> USADO
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/

	DELIMITER $$

			-- apenas Gerente e Funcionario
			DROP PROCEDURE IF EXISTS `funcionario_ticket_usado` $$
			CREATE PROCEDURE `funcionario_ticket_usado`(ticketID INT)
			BEGIN
				DECLARE funcionario_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _funcionario_id INT;
                DECLARE _servico_id INT;
                DECLARE _ticket_id INT;
                DECLARE _estado VARCHAR(45) DEFAULT NULL;
                DECLARE _tempo_espera TIME DEFAULT NULL;
                DECLARE _servico_id_Ticket INT;
                DECLARE _data DATETIME;
                DECLARE _funcionario_Ticket INT DEFAULT NULL;
                DECLARE role VARCHAR(45) DEFAULT NULL;
                DECLARE _gerente_Ticket INT DEFAULT NULL;

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
                -- DECLARE CONTINUE HANDLER FOR NOT FOUND
                
                 DECLARE EXIT HANDLER FOR NOT FOUND
				BEGIN
					ROLLBACK;
					RESIGNAL;
					-- RESIGNAL SET MESSAGE_TEXT = 'An NOT FOUND has occurred, operation rollbacked and the stored procedure was terminated';
				END;
				
                
                START TRANSACTION;
                
                -- id: connection grabber
                /* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				SELECT USER() INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '@', 1) INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '_', 1) INTO role;
				SELECT SUBSTR(funcionario_id_2, 3, 20) INTO funcionario_id_2;


				IF(role = 'F') THEN 
					SELECT MAX(id) INTO _funcionario_id FROM Funcionario WHERE nr_telemovel = funcionario_id_2;
					SELECT servico_id INTO _servico_id FROM Funcionario WHERE id = _funcionario_id;
				ELSE /* role = 'G' */ 
					SELECT MAX(id) INTO _funcionario_id FROM Gerente WHERE nr_telemovel = funcionario_id_2;
					SELECT servico_id INTO _servico_id FROM Gerente WHERE id = _funcionario_id;
				END IF;

				IF(role IS NULL OR (role != 'F' AND role != 'G')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;
                
                -- vars
                -- SELECT id 			  INTO _ticket_id 		   FROM Ticket WHERE id = _ticket_id;
                SET _ticket_id = ticketID;
                SELECT estado 		  INTO _estado 			   FROM Ticket WHERE id = _ticket_id;
                SELECT tempo_espera   INTO _tempo_espera 	   FROM Ticket WHERE id = _ticket_id;
                SELECT servico_id 	  INTO _servico_id_Ticket  FROM Ticket WHERE id = _ticket_id;
                SELECT data 		  INTO _data 			   FROM Ticket WHERE id = _ticket_id;
                
                IF EXISTS (SELECT funcionario_id FROM Ticket WHERE id = _ticket_id)
				THEN
				   SELECT funcionario_id INTO _funcionario_Ticket FROM Ticket WHERE id = _ticket_id;
				END IF;

				IF EXISTS (SELECT gerente_id FROM Ticket WHERE id = _ticket_id)
				THEN
				   SELECT gerente_id INTO _gerente_Ticket FROM Ticket WHERE id = _ticket_id;
				END IF;


                IF(_ticket_id IS NULL) 							THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket - ID Nao existente BD';
					ELSE IF(_estado = 'Usado') 					THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket - Já Usado';
					ELSE IF(_estado = 'Descartado') 			THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket - Já Descartado';
					ELSE IF(_estado = 'Inutilizado') 			THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket - Já Inutilizado';
					ELSE IF(_servico_id_Ticket != _servico_id) 	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket - Servico errado';

					ELSE IF(role = 'F' AND _funcionario_Ticket IS NOT NULL AND  _funcionario_id != _funcionario_Ticket) 	
						THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket - Funcionario diferente';
					ELSE IF(role = 'G' AND _gerente_Ticket IS NOT NULL AND _funcionario_id != _gerente_Ticket) 	
						THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket - Gerente diferente';
				END IF; END IF; END IF; END IF; END IF; END IF; END IF;


				UPDATE Ticket 
					SET estado = 'Usado' 
						WHERE id = _ticket_id;


				SELECT TIMEDIFF(NOW(), ADDTIME(_data,_tempo_espera)) AS tempo_atendimento;

				UPDATE Ticket T
						INNER JOIN Utilizador U
						ON T.utilizador_id = U.id
					SET tempo_atendimento = TIMEDIFF(NOW(), ADDTIME(_data,_tempo_espera)) ,
						U.reputacao = IF(U.reputacao + 0.25 > 5, 5, U.reputacao + 0.25)
						WHERE 
							T.id = _ticket_id AND
							T.utilizador_id = U.id;


				-- »»»»»»»»»»»»»»»»»» notUsedTicketTolerance «««««««««««««««««««««««
				DROP TEMPORARY TABLE IF EXISTS tabela_temp_Tolerance;
                CREATE TEMPORARY TABLE tabela_temp_Tolerance engine=memory 
					SELECT T.id AS ticketID__
						FROM Ticket AS T
                    		WHERE T.data <= _data AND 
                    			   T.id != ticketID AND 
                    			   T.estado = 'Em Espera' AND 
                    			   T.tempo_espera IS NULL AND
                    			   T.servico_id = _servico_id_Ticket;
                
				UPDATE Ticket Ti INNER JOIN tabela_temp_Tolerance TT ON Ti.id = TT.ticketID__
					SET Ti.tolerancia_passagem = Ti.tolerancia_passagem + 1
						WHERE
							Ti.id = TT.ticketID__;

                
				UPDATE Ticket Ti 
						INNER JOIN tabela_temp_Tolerance TT 
						ON Ti.id = TT.ticketID__ 
						INNER JOIN Utilizador U
						ON Ti.utilizador_id = U.id
					SET Ti.estado = 'Inutilizado', -- inutilizado
						U.reputacao = IF(U.reputacao - 0.25 < 0, 0, U.reputacao - 0.25)
						WHERE
							Ti.id = TT.ticketID__ AND
							Ti.tempo_espera IS NULL AND
							Ti.tolerancia_passagem > 3 AND -- 3 senhas de tolerancia
							Ti.utilizador_id = U.id; 
				
                DROP TEMPORARY TABLE IF EXISTS tabela_temp_Tolerance;

                COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`ticket_usado` TO 'funcionario';
            -- FLUSH PRIVILEGES;
 
 
  /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» FUNCIONARIO »» Tickets -> funcionario_anual
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
			-- apenas Gerente e Funcionario
			DROP PROCEDURE IF EXISTS `funcionario_tickets_anual` $$
			CREATE PROCEDURE `funcionario_tickets_anual`()
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE funcionario_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _funcionario_id INT;
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
				SELECT USER() INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '@', 1) INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '_', 1) INTO role;
				SELECT SUBSTR(funcionario_id_2, 3, 20) INTO funcionario_id_2;
				IF(role IS NULL OR (role != 'F' AND role != 'G')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;


				IF(role = 'F') THEN 
					SELECT MAX(id) INTO _funcionario_id FROM Funcionario WHERE nr_telemovel = funcionario_id_2;
					SELECT * FROM Ticket 
                		WHERE funcionario_id = _funcionario_id AND 
                		  	  data >=  (CURDATE() - INTERVAL 1 YEAR) 
                		ORDER BY data DESC;

				ELSE /* role = 'G' */
					SELECT MAX(id) INTO _funcionario_id FROM Gerente WHERE nr_telemovel = funcionario_id_2;
					SELECT * FROM Ticket 
                		WHERE gerente_id = _funcionario_id AND 
                			  data >=  (CURDATE() - INTERVAL 1 YEAR) 
                	ORDER BY data DESC;
				END IF;

                COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`funcionario_tickets_anual` TO 'funcionario';
            -- FLUSH PRIVILEGES;
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» FUNCIONARIO »» Tickets -> funcionario_mensal
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
			-- apenas Gerente e Funcionario
			DROP PROCEDURE IF EXISTS `funcionario_tickets_mensal` $$
			CREATE PROCEDURE `funcionario_tickets_mensal`()
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE funcionario_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _funcionario_id INT;
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
				SELECT USER() INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '@', 1) INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '_', 1) INTO role;
				SELECT SUBSTR(funcionario_id_2, 3, 20) INTO funcionario_id_2;
				IF(role IS NULL OR (role != 'F' AND role != 'G')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;


				IF(role = 'F') THEN 
					SELECT MAX(id) INTO _funcionario_id FROM Funcionario WHERE nr_telemovel = funcionario_id_2;
					SELECT * FROM Ticket 
                		WHERE funcionario_id = _funcionario_id AND 
                		  	  data >=  (CURDATE() - INTERVAL 1 MONTH) 
                		ORDER BY data DESC;

				ELSE /* role = 'G' */
					SELECT MAX(id) INTO _funcionario_id FROM Gerente WHERE nr_telemovel = funcionario_id_2;
					SELECT * FROM Ticket 
                		WHERE gerente_id = _funcionario_id AND 
                			  data >=  (CURDATE() - INTERVAL 1 MONTH) 
                	ORDER BY data DESC;
				END IF;

                COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`funcionario_tickets_mensal` TO 'funcionario';
            -- FLUSH PRIVILEGES;
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» FUNCIONARIO »» Tickets -> funcionario_semanal
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/

			-- apenas Gerente e Funcionario
			DROP PROCEDURE IF EXISTS `funcionario_tickets_semanal` $$
			CREATE PROCEDURE `funcionario_tickets_semanal`()
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE funcionario_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _funcionario_id INT;
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
				SELECT USER() INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '@', 1) INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '_', 1) INTO role;
				SELECT SUBSTR(funcionario_id_2, 3, 20) INTO funcionario_id_2;
				IF(role IS NULL OR (role != 'F' AND role != 'G')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;


				IF(role = 'F') THEN 
					SELECT MAX(id) INTO _funcionario_id FROM Funcionario WHERE nr_telemovel = funcionario_id_2;
					SELECT * FROM Ticket 
                		WHERE funcionario_id = _funcionario_id AND 
                		  	  data >=  (CURDATE() - INTERVAL 1 WEEK) 
                		ORDER BY data DESC;

				ELSE /* role = 'G' */ 
					SELECT MAX(id) INTO _funcionario_id FROM Gerente WHERE nr_telemovel = funcionario_id_2;
					SELECT * FROM Ticket 
                		WHERE gerente_id = _funcionario_id AND 
                			  data >=  (CURDATE() - INTERVAL 1 WEEK) 
                	ORDER BY data DESC;
				END IF;

                COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`funcionario_tickets_semanal` TO 'funcionario';
            -- FLUSH PRIVILEGES;

 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» FUNCIONARIO »» Tickets -> funcionario_dia
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
			-- apenas Gerente e Funcionario
			DROP PROCEDURE IF EXISTS `funcionario_tickets_dia` $$
			CREATE PROCEDURE `funcionario_tickets_dia`()
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE funcionario_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _funcionario_id INT;
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
				SELECT USER() INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '@', 1) INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '_', 1) INTO role;
				SELECT SUBSTR(funcionario_id_2, 3, 20) INTO funcionario_id_2;
				IF(role IS NULL OR (role != 'F' AND role != 'G')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;


				IF(role = 'F') THEN 
					SELECT MAX(id) INTO _funcionario_id FROM Funcionario WHERE nr_telemovel = funcionario_id_2;
					SELECT * FROM Ticket 
                		WHERE funcionario_id = _funcionario_id AND 
                		  	  data >=  (CURDATE() - INTERVAL 1 DAY) 
                		ORDER BY data DESC;

				ELSE /* role = 'G' */ 
					SELECT MAX(id) INTO _funcionario_id FROM Gerente WHERE nr_telemovel = funcionario_id_2;
					SELECT * FROM Ticket 
                		WHERE gerente_id = _funcionario_id AND 
                			  data >=  (CURDATE() - INTERVAL 1 DAY) 
                	ORDER BY data DESC;
				END IF;

                COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`funcionario_tickets_semanal` TO 'funcionario';
            -- FLUSH PRIVILEGES;            
  /*
****************************************************************************************************************************
****************************************************************************************************************************
										PROCEDURES »»»»»»»»» FUNCIONARIO »» AlterarPassword
****************************************************************************************************************************
****************************************************************************************************************************	
 */ 
  			-- apenas o proprio pode chamar
			DROP PROCEDURE IF EXISTS `funcionario_alterar_Password` $$
			CREATE PROCEDURE `funcionario_alterar_Password`(passwd VARCHAR(45))
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE funcionario_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE funcionario_id INT;
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
				SELECT USER() INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '@', 1) INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '_', 1) INTO role;
				SELECT SUBSTR(funcionario_id_2, 3, 20) INTO funcionario_id_2;

				SELECT MAX(id) INTO funcionario_id FROM Funcionario WHERE nr_telemovel = funcionario_id_2;
                IF(role IS NULL OR role != 'F') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;
                
				UPDATE Funcionario SET pass = AES_ENCRYPT(passwd, 'UMinho2020Grupo2') WHERE id = funcionario_id;
				
				set @sql = concat('ALTER USER "F_',funcionario_id_2,'"@"%" IDENTIFIED WITH mysql_native_password BY "',passwd,'" WITH MAX_USER_CONNECTIONS 2');
				PREPARE stmt1 FROM @sql;
				EXECUTE stmt1;
				DEALLOCATE PREPARE stmt1;
				FLUSH PRIVILEGES;

				COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`alterar_Password_Funcionario` TO 'funcionario';
            -- FLUSH PRIVILEGES;
 
 
 
 
 
  /*
****************************************************************************************************************************
****************************************************************************************************************************
										PROCEDURES »»»»»»»»» FUNCIONARIO »» Grants
****************************************************************************************************************************
****************************************************************************************************************************	
 */
	DELIMITER $$
 			-- apenas o admin pode chamar
 			DROP PROCEDURE IF EXISTS `funcionarioUPDATE_PRIVILEGIOS` $$
			CREATE PROCEDURE `funcionarioUPDATE_PRIVILEGIOS`(`user_name` INT)
			BEGIN               
                DECLARE n INT DEFAULT 0;
				DECLARE i INT DEFAULT 0;
                DECLARE procedureName VARCHAR(45);
                DECLARE utilizador_id_3 VARCHAR(45);

                SELECT USER() INTO utilizador_id_3;
				SELECT SUBSTRING_INDEX(utilizador_id_3, '@', 1) INTO utilizador_id_3;

                IF(utilizador_id_3 != 'grupo2' AND utilizador_id_3 NOT LIKE 'G_%') 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;

                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                CREATE TEMPORARY TABLE tabela_temp engine=memory SELECT ROUTINE_NAME AS proc_name FROM INFORMATION_SCHEMA.ROUTINES 
                	WHERE (ROUTINE_TYPE = 'PROCEDURE' AND (ROUTINE_NAME LIKE 'funcionario_%' OR ROUTINE_NAME LIKE 'estatistica_%'));

				SELECT COUNT(*) FROM tabela_temp INTO n;
                
				SET i=0;
				WHILE i<n DO 
					SELECT proc_name INTO procedureName FROM tabela_temp LIMIT i,1;
                    
					set @sql = concat('GRANT EXECUTE ON PROCEDURE iqueue.',procedureName,' TO "F_',user_name,'"@"%"');
					PREPARE stmt1 FROM @sql;
					EXECUTE stmt1;
					DEALLOCATE PREPARE stmt1;
                  
					SET i = i + 1;
				END WHILE;
                
                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                CREATE TEMPORARY TABLE tabela_temp engine=memory SELECT ROUTINE_NAME AS func_name FROM INFORMATION_SCHEMA.ROUTINES 
                	WHERE (ROUTINE_TYPE = 'FUNCTION' AND ROUTINE_NAME LIKE 'funcionario_%');

				SELECT COUNT(*) FROM tabela_temp INTO n;
                
                SET i=0;
				WHILE i<n DO 
					SELECT func_name INTO procedureName FROM tabela_temp LIMIT i,1;
                    
					set @sql = concat('GRANT EXECUTE ON FUNCTION iqueue.',procedureName,' TO "F_',user_name,'"@"%"');
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
									PROCEDURES »»»»»»»»» Funcionario »» GRANTS -> "REMOVE" && REVOKE
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
	DELIMITER $$
			-- apenas admin e o proprio funcionario se pode excluir (gerente tb ?)
 			DROP PROCEDURE IF EXISTS `funcionario_REMOVE` $$
			CREATE PROCEDURE `funcionario_REMOVE`()
            BEGIN
				DECLARE funcionario_id_2 VARCHAR(45);
                DECLARE n INT DEFAULT 0;
				DECLARE i INT DEFAULT 0;
                DECLARE procedureName VARCHAR(45);
                DECLARE utilizador_id_3 VARCHAR(45);
                DECLARE user_name VARCHAR(45);

                SELECT USER() INTO utilizador_id_3;
				SELECT SUBSTRING_INDEX(utilizador_id_3, '@', 1) INTO utilizador_id_3;
                IF(utilizador_id_3 != 'grupo2' AND utilizador_id_3 NOT LIKE 'F_%' AND utilizador_id_3 NOT LIKE 'G_%') 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;
                
                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                CREATE TEMPORARY TABLE tabela_temp engine=memory SELECT ROUTINE_NAME AS proc_name FROM INFORMATION_SCHEMA.ROUTINES 
                	WHERE (ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME LIKE 'funcionario_%');
				SELECT COUNT(*) FROM tabela_temp INTO n;
                

                SELECT SUBSTR(utilizador_id_3, 3, 20) INTO user_name;
                
				SET i=0;
				WHILE i<n DO 
					SELECT proc_name INTO procedureName FROM tabela_temp LIMIT i,1;
                    
					set @sql = concat('REVOKE EXECUTE ON PROCEDURE iqueue.',procedureName,' FROM "F_',user_name,'"@"%"');
					PREPARE stmt1 FROM @sql;
					EXECUTE stmt1;
					DEALLOCATE PREPARE stmt1;
                  
					SET i = i + 1;
				END WHILE;
                
                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                CREATE TEMPORARY TABLE tabela_temp engine=memory SELECT ROUTINE_NAME AS func_name FROM INFORMATION_SCHEMA.ROUTINES WHERE (ROUTINE_TYPE = 'FUNCTION' AND ROUTINE_NAME LIKE 'funcionario_%');
				SELECT COUNT(*) FROM tabela_temp INTO n;
                
                SET i=0;
				WHILE i<n DO 
					SELECT func_name INTO procedureName FROM tabela_temp LIMIT i,1;
                    
					set @sql = concat('REVOKE EXECUTE ON FUNCTION iqueue.',procedureName,' FROM "F_',user_name,'"@"%"');
					PREPARE stmt1 FROM @sql;
					EXECUTE stmt1;
					DEALLOCATE PREPARE stmt1;
                  
					SET i = i + 1;
				END WHILE;
                
				FLUSH PRIVILEGES;
    			
				set @sql = concat('DROP USER "F_',user_name,'"@"%"');
				PREPARE stmt1 FROM @sql;
				EXECUTE stmt1;
				DEALLOCATE PREPARE stmt1;
                
				DROP TEMPORARY TABLE IF EXISTS tabela_temp;

            END $$
			-- GRANT EXECUTE ON PROCEDURE `iqueue`.`funcionario_REMOVE` TO 'funcionario';
            -- FLUSH PRIVILEGES;
            

 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» Funcionario »» GRANTS -> "REMOVE" && REVOKE
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
	DELIMITER $$
			-- apenas admin e o proprio funcionario se pode excluir (gerente tb ?)
 			DROP PROCEDURE IF EXISTS `funcionario_REMOVE_id` $$
			CREATE PROCEDURE `funcionario_REMOVE_id`(func_id INT)
            BEGIN
				DECLARE funcionario_id_2 VARCHAR(45);
                DECLARE n INT DEFAULT 0;
				DECLARE i INT DEFAULT 0;
                DECLARE procedureName VARCHAR(45);
                DECLARE utilizador_id_3 VARCHAR(45);
                DECLARE user_name VARCHAR(45);
                DECLARE _servico_id INT;
                DECLARE grupo INT DEFAULT NULL;

                SELECT USER() INTO utilizador_id_3;
				SELECT SUBSTRING_INDEX(utilizador_id_3, '@', 1) INTO utilizador_id_3;
                IF(utilizador_id_3 != 'grupo2' AND utilizador_id_3 NOT LIKE 'G_%') 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;


                SELECT SUBSTR(utilizador_id_3, 3, 20) INTO user_name;

                SELECT servico_id INTO _servico_id FROM Gerente WHERE nr_telemovel = user_name;
                SELECT id INTO grupo FROM Funcionario WHERE servico_id = _servico_id AND id = func_id;

                IF(grupo IS NULL) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Funcionario não pertence ao servico deste gerente';
				END IF;

				SELECT nr_telemovel INTO user_name FROM Funcionario WHERE id = func_id;
                
				DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                CREATE TEMPORARY TABLE tabela_temp engine=memory SELECT ROUTINE_NAME AS proc_name FROM INFORMATION_SCHEMA.ROUTINES 
                	WHERE (ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME LIKE 'funcionario_%');
				SELECT COUNT(*) FROM tabela_temp INTO n;
                
                
				SET i=0;
				WHILE i<n DO 
					SELECT proc_name INTO procedureName FROM tabela_temp LIMIT i,1;
                    
					set @sql = concat('REVOKE EXECUTE ON PROCEDURE iqueue.',procedureName,' FROM "F_',user_name,'"@"%"');
					PREPARE stmt1 FROM @sql;
					EXECUTE stmt1;
					DEALLOCATE PREPARE stmt1;
                  
					SET i = i + 1;
				END WHILE;
                
                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                CREATE TEMPORARY TABLE tabela_temp engine=memory SELECT ROUTINE_NAME AS func_name FROM INFORMATION_SCHEMA.ROUTINES WHERE (ROUTINE_TYPE = 'FUNCTION' AND ROUTINE_NAME LIKE 'funcionario_%');
				SELECT COUNT(*) FROM tabela_temp INTO n;
                
                SET i=0;
				WHILE i<n DO 
					SELECT func_name INTO procedureName FROM tabela_temp LIMIT i,1;
                    
					set @sql = concat('REVOKE EXECUTE ON FUNCTION iqueue.',procedureName,' FROM "F_',user_name,'"@"%"');
					PREPARE stmt1 FROM @sql;
					EXECUTE stmt1;
					DEALLOCATE PREPARE stmt1;
                  
					SET i = i + 1;
				END WHILE;
                
				FLUSH PRIVILEGES;
    			
				set @sql = concat('DROP USER "F_',user_name,'"@"%"');
				PREPARE stmt1 FROM @sql;
				EXECUTE stmt1;
				DEALLOCATE PREPARE stmt1;
                
				DROP TEMPORARY TABLE IF EXISTS tabela_temp;

            END $$
			-- GRANT EXECUTE ON PROCEDURE `iqueue`.`funcionario_REMOVE` TO 'funcionario';
            -- FLUSH PRIVILEGES;