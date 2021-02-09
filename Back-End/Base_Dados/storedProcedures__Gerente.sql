
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

		-- CREATE ROLE 'gerente';
        
		DELIMITER $$
        
/* 
****************************************************************************************************************************
****************************************************************************************************************************
												PROCEDURES »»»»»»»»» GERENTE
****************************************************************************************************************************
****************************************************************************************************************************
*/

/* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
											PROCEDURES »»»»»»»»» GERENTE »» INIT 
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
			DROP PROCEDURE IF EXISTS `create_gerente` $$
			CREATE PROCEDURE `create_gerente`(`user_name` INT, `passwd` VARCHAR(45), `_servico_id` INT)
			BEGIN
				DECLARE utilizador_id_3 VARCHAR(45);

                SELECT USER() INTO utilizador_id_3;
				SELECT SUBSTRING_INDEX(utilizador_id_3, '@', 1) INTO utilizador_id_3;


                IF(utilizador_id_3 != 'grupo2') 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;


			   set @sql = CONCAT('CREATE USER "G_',user_name,'"@"%" IDENTIFIED WITH mysql_native_password BY "',passwd,'" WITH MAX_USER_CONNECTIONS 3'); 
			   PREPARE stmt1 FROM @sql;
			   EXECUTE stmt1;
			   DEALLOCATE PREPARE stmt1;
			   
               /*
			   set @sql = concat("GRANT 'gerente' TO '",`user_name`,"'@'%' WITH max_user_connections 1");
			   PREPARE stmt2 FROM @sql;
			   EXECUTE stmt2;
			   DEALLOCATE PREPARE stmt2;
               */
                
			   CALL gerenteUPDATE_PRIVILEGIOS(user_name);
               
			   
			   INSERT INTO Gerente(nr_telemovel, pass, servico_id) VALUES (user_name, AES_ENCRYPT(passwd, 'UMinho2020Grupo2'), _servico_id);

			   
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`create_gerente` TO '??????'; -- <<<<<<<<----------------------------------------
            -- FLUSH PRIVILEGES;

 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
										PROCEDURES »»»»»»»»» GERENTE »» AlterarPassword 
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
	DELIMITER $$
			DROP PROCEDURE IF EXISTS `gerente_alterar_password` $$
			CREATE PROCEDURE `gerente_alterar_password`(passwd VARCHAR(45))
			BEGIN
				/* Camada extra de segurança - garante que não deixa criar tickets para outros utilizadores que não o próprio
						» protege os dados/servidor se a máquina-cliente for atacada
                
					Exemplo -> o backend/frontend foi atacado/alterado, enviando um utilizador_id/telefone diferente da conexão como argumento da procedure 
						Solução -> remover esse argumento, trabalhando sobre a conexão em si para identificar o remetente (que é em SSL e codificação hash 256 para password)
                    
                    Nota - não impede de o utilizador ou atacante de invocar várias vezes a procedure
						Solução - Apenas podemos limitar o nº de tickets_em_espera/hora
                */
				DECLARE user_name VARCHAR(45);
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

                SELECT USER() INTO user_name;
				SELECT SUBSTRING_INDEX(user_name, '@', 1) INTO user_name;
				SELECT SUBSTRING_INDEX(user_name, '_', 1) INTO role;
				SELECT SUBSTR(user_name, 3, 20) INTO user_name;


                IF(user_name != 'grupo2' AND role != 'G') 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;

				UPDATE Gerente SET pass = AES_ENCRYPT(passwd, 'UMinho2020Grupo2') WHERE id = user_name;
				
				set @sql = concat('ALTER USER "G_',user_name,'"@"%" IDENTIFIED WITH mysql_native_password BY "',passwd,'" WITH MAX_USER_CONNECTIONS 3');
				PREPARE stmt1 FROM @sql;
				EXECUTE stmt1;
				DEALLOCATE PREPARE stmt1;
				FLUSH PRIVILEGES;

				COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`alterar_Password_Gerente` TO 'gerente';
            -- FLUSH PRIVILEGES;
 

  /*
****************************************************************************************************************************
****************************************************************************************************************************
										PROCEDURES »»»»»»»»» GERENTE »» FUNCIONARIOS
****************************************************************************************************************************
****************************************************************************************************************************	
 */

/* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
										PROCEDURES »»»»»»»»» GERENTE »» FUNCIONARIOS »» CRIA FUNCIONARIO
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
 DELIMITER $$
			DROP PROCEDURE IF EXISTS `gerente_cria_funcionario` $$
			CREATE PROCEDURE `gerente_cria_funcionario`(`user_name` INT, `passwd` VARCHAR(45), `nome` VARCHAR(255))
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE gerente_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _gerente_id INT;
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

                SELECT USER() INTO gerente_id_2;
				SELECT SUBSTRING_INDEX(gerente_id_2, '@', 1) INTO gerente_id_2;

				SELECT SUBSTRING_INDEX(gerente_id_2, '_', 1) INTO role;
				SELECT SUBSTR(gerente_id_2, 3, 20) INTO gerente_id_2;


				SELECT MAX(id) INTO _gerente_id FROM Gerente WHERE nr_telemovel = gerente_id_2;
                IF(role != 'G') 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;


                SELECT servico_id INTO _servico_id FROM Gerente WHERE id = _gerente_id;
                
                CALL create_funcionario_2(user_name, passwd, _servico_id, nome);
                
                COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`cria_funcionario` TO 'gerente';
            -- FLUSH PRIVILEGES;

/* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
										PROCEDURES »»»»»»»»» GERENTE »» FUNCIONARIOS »» REMOVE FUNCIONARIO
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
 DELIMITER $$
			DROP PROCEDURE IF EXISTS `gerente_remove_funcionario` $$
			CREATE PROCEDURE `gerente_remove_funcionario`(`func_id` INT)
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE gerente_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _gerente_id INT;
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

                SELECT USER() INTO gerente_id_2;
				SELECT SUBSTRING_INDEX(gerente_id_2, '@', 1) INTO gerente_id_2;

				SELECT SUBSTRING_INDEX(gerente_id_2, '_', 1) INTO role;
				SELECT SUBSTR(gerente_id_2, 3, 20) INTO gerente_id_2;


				SELECT MAX(id) INTO _gerente_id FROM Gerente WHERE nr_telemovel = gerente_id_2;
                IF(role != 'G') 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;


                SELECT servico_id INTO _servico_id FROM Gerente WHERE id = _gerente_id;
                
                CALL funcionario_REMOVE_id(func_id);
                
                COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`cria_funcionario` TO 'gerente';
            -- FLUSH PRIVILEGES;
  /*
****************************************************************************************************************************
****************************************************************************************************************************
										PROCEDURES »»»»»»»»» GERENTE »» SERVICO
****************************************************************************************************************************
****************************************************************************************************************************	
 */
 
 
/* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
										PROCEDURES »»»»»»»»» GERENTE »» SERVICO »» INIT
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
 
			DROP PROCEDURE IF EXISTS `create_servico` $$
			CREATE PROCEDURE `create_servico`(`nome` VARCHAR(45), `categoria` VARCHAR(45), `hora_abertura` TIME, `hora_fecho` TIME, `latitude` DOUBLE, `longitude` DOUBLE, `estado` BOOLEAN)
			BEGIN
				DECLARE last_id INT;
				DECLARE last_date DATE;

				DECLARE user_name VARCHAR(45);
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

                SELECT USER() INTO user_name;
				SELECT SUBSTRING_INDEX(user_name, '@', 1) INTO user_name;

				SELECT SUBSTRING_INDEX(user_name, '_', 1) INTO role;
				SELECT SUBSTR(user_name, 3, 20) INTO user_name;


				SELECT MAX(id) INTO last_id FROM Gerente WHERE nr_telemovel = user_name;
                IF(user_name != 'grupo2' AND role != 'G') 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;

                SELECT MAX(id) INTO last_id FROM Servico;
                SET last_id = last_id + 1;
                
				INSERT INTO Estatistica_Tempo_Real (servico_id) VALUES (last_id);
				
				INSERT INTO Servico (id, nome, categoria, hora_abertura, hora_fecho, latitude, longitude, estado, estatistica_tempo_real, ticket_atual)
					VALUES (last_id, nome, categoria, hora_abertura, hora_fecho, latitude, longitude, estado, last_id, 0);


				INSERT INTO Estatistica_Diaria  (data, servico_id) VALUES (DATE(NOW()), last_id);

				SELECT MAX(data) INTO last_date FROM Estatistica_Semanal;
				INSERT INTO Estatistica_Semanal (data, servico_id) VALUES (last_date, last_id);

				SELECT MAX(data) INTO last_date FROM Estatistica_Mensal;
				INSERT INTO Estatistica_Mensal  (data, servico_id) VALUES (last_date, last_id);

				COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`create_servico` TO 'gerente'; -- <<<<<<<<----------------------------------------
            -- FLUSH PRIVILEGES;
 
 

/* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
										PROCEDURES »»»»»»»»» GERENTE »» SERVICO »» UPDATE ESTADO
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
 DELIMITER $$
			DROP PROCEDURE IF EXISTS `gerente_servico_estado` $$
			CREATE PROCEDURE `gerente_servico_estado`(`_estado` INT)
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE gerente_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _gerente_id INT;
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

                SELECT USER() INTO gerente_id_2;
				SELECT SUBSTRING_INDEX(gerente_id_2, '@', 1) INTO gerente_id_2;

				SELECT SUBSTRING_INDEX(gerente_id_2, '_', 1) INTO role;
				SELECT SUBSTR(gerente_id_2, 3, 20) INTO gerente_id_2;


				SELECT MAX(id) INTO _gerente_id FROM Gerente WHERE nr_telemovel = gerente_id_2;
                IF(role != 'G') 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;


                SELECT servico_id INTO _servico_id FROM Gerente WHERE id = _gerente_id;
                
                UPDATE Servico SET estado = _estado WHERE id = _servico_id;

                UPDATE Ticket 
					SET estado = 'Descartado' ,-- descartado
						observacoes = 
							COALESCE(concat(observacoes,'\nSistema fechou o ticket automaticamente pois servico foi fechado de forma forcada. Para mais informacoes contactar o servico respectivo'),
									 'Sistema fechou o ticket automaticamente pois servico foi fechado de forma forcada. Para mais informacoes contactar o servico respectivo')
                WHERE DATE(data) = DATE(NOW()) AND servico_id = _servico_id AND 
					  estado = 'Em Espera' AND tempo_espera IS NULL;
                
                COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`gerente_servico_estado` TO 'gerente';
            -- FLUSH PRIVILEGES;
            

  /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
										PROCEDURES »»»»»»»»» GERENTE »» SERVICO »» Get Funcionarios
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
 DELIMITER $$
			DROP PROCEDURE IF EXISTS `gerente_servico_getFuncionarios` $$
			CREATE PROCEDURE `gerente_servico_getFuncionarios`()
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE gerente_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _gerente_id INT;
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

                SELECT USER() INTO gerente_id_2;
				SELECT SUBSTRING_INDEX(gerente_id_2, '@', 1) INTO gerente_id_2;

				SELECT SUBSTRING_INDEX(gerente_id_2, '_', 1) INTO role;
				SELECT SUBSTR(gerente_id_2, 3, 20) INTO gerente_id_2;


				SELECT MAX(id) INTO _gerente_id FROM Gerente WHERE nr_telemovel = gerente_id_2;
                IF(role != 'G') 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;


                SELECT servico_id INTO _servico_id FROM Gerente WHERE id = _gerente_id;
                
                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
				CREATE TEMPORARY TABLE tabela_temp engine=memory 
							SELECT nr_telemovel, id AS funcionario_id, Nome FROM Funcionario WHERE servico_id = _servico_id;


				DROP TEMPORARY TABLE IF EXISTS tabela_temp2;
				CREATE TEMPORARY TABLE tabela_temp2 engine=memory 
							SELECT SUBSTR(User, 3, 20) AS nr FROM mysql.user WHERE user LIKE 'F_%';
                
                SELECT DISTINCT nr_telemovel, funcionario_id, nome FROM tabela_temp AS T INNER JOIN tabela_temp2 AS TT 
							ON T.nr_telemovel = TT.nr  
                            WHERE T.nr_telemovel = TT.nr
                            ORDER BY funcionario_id ASC;
				
				DROP TEMPORARY TABLE IF EXISTS tabela_temp2;
				DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                
                COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`getFuncionarios` TO 'gerente';
            -- FLUSH PRIVILEGES;

 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» GERENTE »» Servico -> GET horario 
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
	DELIMITER $$
			-- no ultimo dia
			DROP PROCEDURE IF EXISTS `gerente_servico_horario` $$
			CREATE PROCEDURE `gerente_servico_horario`()
			BEGIN      
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE gerente_id_2 VARCHAR(45);
                DECLARE _gerente_id INT;
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
                
				SELECT USER() INTO gerente_id_2;
				SELECT SUBSTRING_INDEX(gerente_id_2, '@', 1) INTO gerente_id_2;
				SELECT SUBSTRING_INDEX(gerente_id_2, '_', 1) INTO role;
				
				SELECT SUBSTR(gerente_id_2, 3, 20) INTO _gerente_id;
                
                IF(role IS NULL OR role != 'G') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

                SELECT servico_id INTO _servico_id FROM Gerente WHERE nr_telemovel = _gerente_id;
				
				SELECT hora_abertura, hora_fecho FROM Servico WHERE id = _servico_id;

				COMMIT;

			END$$


  /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
										PROCEDURES »»»»»»»»» GERENTE »» SERVICO »» UPDATE HORARIO ATENDIMENTO
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
 
			DROP PROCEDURE IF EXISTS `gerente_servico_atendimento` $$
			CREATE PROCEDURE `gerente_servico_atendimento`(`hora_a` INT, `min_a` INT, `hora_f` INT, `min_f` INT)
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE gerente_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _gerente_id INT;
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

                SELECT USER() INTO gerente_id_2;
				SELECT SUBSTRING_INDEX(gerente_id_2, '@', 1) INTO gerente_id_2;

				SELECT SUBSTRING_INDEX(gerente_id_2, '_', 1) INTO role;
				SELECT SUBSTR(gerente_id_2, 3, 20) INTO gerente_id_2;

                IF(role != 'G') 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;
				
				SELECT MAX(id) INTO _gerente_id FROM Gerente WHERE nr_telemovel = gerente_id_2;
				SELECT servico_id INTO _servico_id FROM Gerente WHERE id = _gerente_id;

                UPDATE Servico SET hora_abertura = TIME(concat(hora_a,':',min_a,':00')) ,
                				   hora_fecho = TIME(concat(hora_f,':',min_f,':00'))
                	 WHERE id = _servico_id;
                
                COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`gerente_servico_atendimento` TO 'gerente';
            -- FLUSH PRIVILEGES;
            

 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
										PROCEDURES »»»»»»»»» GERENTE »» SERVICO »» UPDATE REPUTACAO
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
 DELIMITER $$
			DROP PROCEDURE IF EXISTS `gerente_servico_reputacao` $$
			CREATE PROCEDURE `gerente_servico_reputacao`(`_reputacao` FLOAT(4))
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE gerente_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _gerente_id INT;
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

				SELECT USER() INTO gerente_id_2;
				SELECT SUBSTRING_INDEX(gerente_id_2, '@', 1) INTO gerente_id_2;

				SELECT SUBSTRING_INDEX(gerente_id_2, '_', 1) INTO role;
				SELECT SUBSTR(gerente_id_2, 3, 20) INTO gerente_id_2;

				SELECT MAX(id) INTO _gerente_id FROM Gerente WHERE nr_telemovel = gerente_id_2;
				IF(role != 'G') 
					THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

                SELECT servico_id INTO _servico_id FROM Gerente WHERE id = _gerente_id;
                
                SELECT _servico_id, _reputacao;
                
                START TRANSACTION;
                UPDATE Servico SET reputacao_min = _reputacao WHERE id = _servico_id;
                
                COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`gerente_servico_reputacao` TO 'gerente';
            -- FLUSH PRIVILEGES;
 
  /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
										PROCEDURES »»»»»»»»» GERENTE »» SERVICO »» UPDATE LOCALIZACAO
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
 
			DROP PROCEDURE IF EXISTS `gerente_servico_localizacao` $$
			CREATE PROCEDURE `gerente_servico_localizacao`(`info` VARCHAR(45))
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE gerente_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _gerente_id INT;
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

				SELECT USER() INTO gerente_id_2;
				SELECT SUBSTRING_INDEX(gerente_id_2, '@', 1) INTO gerente_id_2;

				SELECT SUBSTRING_INDEX(gerente_id_2, '_', 1) INTO role;
				SELECT SUBSTR(gerente_id_2, 3, 20) INTO gerente_id_2;

				SELECT MAX(id) INTO _gerente_id FROM Gerente WHERE nr_telemovel = gerente_id_2;
				IF(role != 'G') 
					THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

                SELECT servico_id INTO _servico_id FROM Gerente WHERE id = _gerente_id;
                
                UPDATE Servico SET localizacao = info WHERE id = _servico_id;
                
                COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`gerente_servico_localizacao` TO 'gerente';
            -- FLUSH PRIVILEGES;


 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» GERENTE »» Tickets -> GET (LAST 24H)
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
	DELIMITER $$
			-- no ultimo dia
			DROP PROCEDURE IF EXISTS `gerente_get_tickets` $$
			CREATE PROCEDURE `gerente_get_tickets`()
			BEGIN      
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE gerente_id_2 VARCHAR(45);
                DECLARE _gerente_id INT;
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
					RESIGNAL SET MESSAGE_TEXT = 'An SQLEXCEPTION has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR SQLWARNING 
				BEGIN
					ROLLBACK;
					RESIGNAL SET MESSAGE_TEXT = 'An SQLWARNING has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                 DECLARE EXIT HANDLER FOR NOT FOUND
				BEGIN
					ROLLBACK;
					RESIGNAL SET MESSAGE_TEXT = 'An NOT FOUND has occurred, operation rollbacked and the stored procedure was terminated';
				END;
                
                START TRANSACTION;
                
				SELECT USER() INTO gerente_id_2;
				SELECT SUBSTRING_INDEX(gerente_id_2, '@', 1) INTO gerente_id_2;
				SELECT SUBSTRING_INDEX(gerente_id_2, '_', 1) INTO role;
				SELECT SUBSTR(gerente_id_2, 3, 20) INTO gerente_id_2;
                IF(role IS NULL OR role != 'G') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

                SELECT MAX(id) INTO _gerente_id FROM Gerente WHERE nr_telemovel = gerente_id_2;
                SELECT servico_id INTO _servico_id FROM Gerente WHERE id = _gerente_id;
				

				SELECT * FROM Ticket 
						WHERE
							servico_id = _servico_id AND
                            estado = 'Em Espera' AND 
                            tempo_espera IS NULL AND
                            data >= (CURDATE() - INTERVAL 1 DAY) 
						ORDER BY id DESC;

				COMMIT;

			END$$

 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» GERENTE »» SERVICO »» Tickets -> funcionario_anual
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/

			DROP PROCEDURE IF EXISTS `gerente_tickets_anual` $$
			CREATE PROCEDURE `gerente_tickets_anual`(`_funcionario_id` INT)
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE gerente_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _gerente_id INT;
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
				
				SELECT USER() INTO gerente_id_2;
				SELECT SUBSTRING_INDEX(gerente_id_2, '@', 1) INTO gerente_id_2;

				SELECT SUBSTRING_INDEX(gerente_id_2, '_', 1) INTO role;
				SELECT SUBSTR(gerente_id_2, 3, 20) INTO gerente_id_2;

				SELECT MAX(id) INTO _gerente_id FROM Gerente WHERE nr_telemovel = gerente_id_2;
				IF(role != 'G') 
					THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;


				SELECT servico_id INTO _servico_id FROM Gerente WHERE id = _gerente_id;

                SELECT * FROM Ticket 
					WHERE 
						servico_id = _servico_id AND 
                        funcionario_id = _funcionario_id AND 
                        (data BETWEEN (CURDATE() - INTERVAL 1 YEAR) AND CURDATE()) 
                        
					ORDER BY data DESC;

				COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`gerente_tickets_anual` TO 'gerente';
            -- FLUSH PRIVILEGES;
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» GERENTE »» SERVICO »» Tickets -> funcionario_mensal
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/

			DROP PROCEDURE IF EXISTS `gerente_tickets_mensal` $$
			CREATE PROCEDURE `gerente_tickets_mensal`(`_funcionario_id` INT)
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE gerente_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _gerente_id INT;
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
				
				SELECT USER() INTO gerente_id_2;
				SELECT SUBSTRING_INDEX(gerente_id_2, '@', 1) INTO gerente_id_2;

				SELECT SUBSTRING_INDEX(gerente_id_2, '_', 1) INTO role;
				SELECT SUBSTR(gerente_id_2, 3, 20) INTO gerente_id_2;

				SELECT MAX(id) INTO _gerente_id FROM Gerente WHERE nr_telemovel = gerente_id_2;
				IF(role != 'G') 
					THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;


               SELECT servico_id INTO _servico_id FROM Gerente WHERE id = _gerente_id;

                SELECT * FROM Ticket 
					WHERE 
						servico_id = _servico_id AND 
                        funcionario_id = _funcionario_id AND 
                        (data BETWEEN (CURDATE() - INTERVAL 1 MONTH) AND CURDATE()) 
                        
					ORDER BY data DESC;

				COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`funcionario_tickets_mensal` TO 'gerente';
            -- FLUSH PRIVILEGES;
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» GERENTE »» SERVICO »» Tickets -> funcionario_semanal
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/

			DROP PROCEDURE IF EXISTS `gerente_tickets_semanal` $$
			CREATE PROCEDURE `gerente_tickets_semanal`(`_funcionario_id` INT)
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE gerente_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _gerente_id INT;
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
				
				SELECT USER() INTO gerente_id_2;
				SELECT SUBSTRING_INDEX(gerente_id_2, '@', 1) INTO gerente_id_2;

				SELECT SUBSTRING_INDEX(gerente_id_2, '_', 1) INTO role;
				SELECT SUBSTR(gerente_id_2, 3, 20) INTO gerente_id_2;

				SELECT MAX(id) INTO _gerente_id FROM Gerente WHERE nr_telemovel = gerente_id_2;
				IF(role != 'G') 
					THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;


                SELECT servico_id INTO _servico_id FROM Gerente WHERE id = _gerente_id;

                SELECT * FROM Ticket 
					WHERE 
						servico_id = _servico_id AND  
                        funcionario_id = _funcionario_id AND 
                        (data BETWEEN (CURDATE() - INTERVAL 1 WEEK) AND CURDATE()) 
                        
					ORDER BY data DESC;

				COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`gerente_tickets_semanal` TO 'gerente';
            -- FLUSH PRIVILEGES;

 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» GERENTE »» SERVICO »» Tickets -> funcionario_dia
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/

			DROP PROCEDURE IF EXISTS `gerente_tickets_dia` $$
			CREATE PROCEDURE `gerente_tickets_dia`(`_funcionario_id` INT)
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE gerente_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _gerente_id INT;
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

				SELECT USER() INTO gerente_id_2;
				SELECT SUBSTRING_INDEX(gerente_id_2, '@', 1) INTO gerente_id_2;

				SELECT SUBSTRING_INDEX(gerente_id_2, '_', 1) INTO role;
				SELECT SUBSTR(gerente_id_2, 3, 20) INTO gerente_id_2;

				SELECT MAX(id) INTO _gerente_id FROM Gerente WHERE nr_telemovel = gerente_id_2;
				IF(role != 'G')  
					THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

                SELECT servico_id INTO _servico_id FROM Gerente WHERE id = _gerente_id;

                SELECT * FROM Ticket 
					WHERE 
						servico_id = _servico_id AND 
                        funcionario_id = _funcionario_id AND 
                        DATE(data) = DATE(NOW()) 
                        
					ORDER BY data DESC;

				COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`gerente_tickets_dia` TO 'gerente';
            -- FLUSH PRIVILEGES; 
 
  /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» GERENTE »» SERVICO »» Tickets -> gerente_anual
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/

			DROP PROCEDURE IF EXISTS `gerente_tickets_anual_G` $$
			CREATE PROCEDURE `gerente_tickets_anual_G`()
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE gerente_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _gerente_id INT;

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
				
				SELECT USER() INTO gerente_id_2;
				SELECT SUBSTRING_INDEX(gerente_id_2, '@', 1) INTO gerente_id_2;

				SELECT SUBSTRING_INDEX(gerente_id_2, '_', 1) INTO role;
				SELECT SUBSTR(gerente_id_2, 3, 20) INTO gerente_id_2;

				SELECT MAX(id) INTO _gerente_id FROM Gerente WHERE nr_telemovel = gerente_id_2;
				IF(role != 'G') 
					THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

                SELECT * FROM Ticket 
					WHERE 
						gerente_id = _gerente_id AND
                        (data BETWEEN (CURDATE() - INTERVAL 1 YEAR) AND CURDATE()) 
                        
					ORDER BY data DESC;

				COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`gerente_tickets_anual_G` TO 'gerente';
            -- FLUSH PRIVILEGES;
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» GERENTE »» SERVICO »» Tickets -> funcionario_mensal
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/

			DROP PROCEDURE IF EXISTS `gerente_tickets_mensal_G` $$
			CREATE PROCEDURE `gerente_tickets_mensal_G`()
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE gerente_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _gerente_id INT;

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
				
				SELECT USER() INTO gerente_id_2;
				SELECT SUBSTRING_INDEX(gerente_id_2, '@', 1) INTO gerente_id_2;

				SELECT SUBSTRING_INDEX(gerente_id_2, '_', 1) INTO role;
				SELECT SUBSTR(gerente_id_2, 3, 20) INTO gerente_id_2;

				SELECT MAX(id) INTO _gerente_id FROM Gerente WHERE nr_telemovel = gerente_id_2;
				IF(role != 'G') 
					THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

                SELECT * FROM Ticket 
					WHERE 
						gerente_id = _gerente_id AND 
                        (data BETWEEN (CURDATE() - INTERVAL 1 MONTH) AND CURDATE()) 
                        
					ORDER BY data DESC;

				COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`gerente_tickets_mensal_G` TO 'gerente';
            -- FLUSH PRIVILEGES;
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» GERENTE »» SERVICO »» Tickets -> funcionario_semanal
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/

			DROP PROCEDURE IF EXISTS `gerente_tickets_semanal_G` $$
			CREATE PROCEDURE `gerente_tickets_semanal_G`()
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE gerente_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _gerente_id INT;

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
				
				SELECT USER() INTO gerente_id_2;
				SELECT SUBSTRING_INDEX(gerente_id_2, '@', 1) INTO gerente_id_2;

				SELECT SUBSTRING_INDEX(gerente_id_2, '_', 1) INTO role;
				SELECT SUBSTR(gerente_id_2, 3, 20) INTO gerente_id_2;

				SELECT MAX(id) INTO _gerente_id FROM Gerente WHERE nr_telemovel = gerente_id_2;
				IF(role != 'G') 
					THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

                SELECT * FROM Ticket 
					WHERE 
						gerente_id = _gerente_id AND 
                        (data BETWEEN (CURDATE() - INTERVAL 1 WEEK) AND CURDATE()) 
                        
					ORDER BY data DESC;

				COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`gerente_tickets_semanal` TO 'gerente';
            -- FLUSH PRIVILEGES;

 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» GERENTE »» SERVICO »» Tickets -> funcionario_dia
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/

			DROP PROCEDURE IF EXISTS `gerente_tickets_dia_G` $$
			CREATE PROCEDURE `gerente_tickets_dia_G`()
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE gerente_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _gerente_id INT;
                
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
				
				SELECT USER() INTO gerente_id_2;
				SELECT SUBSTRING_INDEX(gerente_id_2, '@', 1) INTO gerente_id_2;

				SELECT SUBSTRING_INDEX(gerente_id_2, '_', 1) INTO role;
				SELECT SUBSTR(gerente_id_2, 3, 20) INTO gerente_id_2;

				SELECT MAX(id) INTO _gerente_id FROM Gerente WHERE nr_telemovel = gerente_id_2;
				IF(role != 'G') 
					THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

                SELECT * FROM Ticket 
					WHERE 
						gerente_id = _gerente_id AND
                        DATE(data) = DATE(NOW()) 
                        
					ORDER BY data DESC;

				COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`gerente_tickets_dia_G` TO 'gerente';
            -- FLUSH PRIVILEGES; 
 
 
/*
****************************************************************************************************************************
****************************************************************************************************************************
										PROCEDURES »»»»»»»»» GERENTE »» Grants
****************************************************************************************************************************
****************************************************************************************************************************	
 */
 
 DELIMITER $$
 
 			DROP PROCEDURE IF EXISTS `gerenteUPDATE_PRIVILEGIOS` $$
			CREATE PROCEDURE `gerenteUPDATE_PRIVILEGIOS`(`user_name` INT)
			BEGIN
                DECLARE n INT DEFAULT 0;
				DECLARE i INT DEFAULT 0;
                DECLARE procedureName VARCHAR(45);
                 DECLARE utilizador_id_3 VARCHAR(45);
                -- DECLARE utilizador_id_4 INT;

                SELECT USER() INTO utilizador_id_3;
				SELECT SUBSTRING_INDEX(utilizador_id_3, '@', 1) INTO utilizador_id_3;
				-- SELECT MAX(id),  INTO utilizador_id_4 FROM Funcionario WHERE nr_telemovel = utilizador_id_3;
                IF(utilizador_id_3 != 'guestDB' AND utilizador_id_3 != 'grupo2') 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;

                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                CREATE TEMPORARY TABLE tabela_temp engine=memory SELECT ROUTINE_NAME AS proc_name FROM INFORMATION_SCHEMA.ROUTINES WHERE (ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME LIKE 'gerente_%');
				SELECT COUNT(*) FROM tabela_temp INTO n;
                
				SET i=0;
				WHILE i<n DO 
					SELECT proc_name INTO procedureName FROM tabela_temp LIMIT i,1;
                    
					set @sql = concat('GRANT EXECUTE ON PROCEDURE iqueue.',procedureName,' TO "G_',user_name,'"@"%"');
					PREPARE stmt1 FROM @sql;
					EXECUTE stmt1;
					DEALLOCATE PREPARE stmt1;
                  
					SET i = i + 1;
				END WHILE;
                
                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                CREATE TEMPORARY TABLE tabela_temp engine=memory SELECT ROUTINE_NAME AS func_name FROM INFORMATION_SCHEMA.ROUTINES WHERE (ROUTINE_TYPE = 'FUNCTION' AND ROUTINE_NAME LIKE 'gerente_%');
				SELECT COUNT(*) FROM tabela_temp INTO n;
                
                SET i=0;
				WHILE i<n DO 
					SELECT func_name INTO procedureName FROM tabela_temp LIMIT i,1;
                    
					set @sql = concat('GRANT EXECUTE ON FUNCTION iqueue.',procedureName,' TO "G_',user_name,'"@"%"');
					PREPARE stmt1 FROM @sql;
					EXECUTE stmt1;
					DEALLOCATE PREPARE stmt1;
                  
					SET i = i + 1;
				END WHILE;
                
                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
				FLUSH PRIVILEGES;

				set @sql = concat('GRANT EXECUTE ON PROCEDURE iqueue.funcionario_atender_ticket TO "G_',user_name,'"@"%"');
				PREPARE stmt1 FROM @sql;
				EXECUTE stmt1;
				DEALLOCATE PREPARE stmt1;
				FLUSH PRIVILEGES;

				set @sql = concat('GRANT EXECUTE ON PROCEDURE iqueue.funcionario_get_tickets TO "G_',user_name,'"@"%"');
				PREPARE stmt1 FROM @sql;
				EXECUTE stmt1;
				DEALLOCATE PREPARE stmt1;
				FLUSH PRIVILEGES;


				set @sql = concat('GRANT EXECUTE ON PROCEDURE iqueue.funcionario_ticket_usado TO "G_',user_name,'"@"%"');
				PREPARE stmt1 FROM @sql;
				EXECUTE stmt1;
				DEALLOCATE PREPARE stmt1;
				FLUSH PRIVILEGES;

				set @sql = concat('GRANT EXECUTE ON PROCEDURE iqueue.create_funcionario TO "G_',user_name,'"@"%"');
				PREPARE stmt1 FROM @sql;
				EXECUTE stmt1;
				DEALLOCATE PREPARE stmt1;
				FLUSH PRIVILEGES;

				set @sql = concat('GRANT EXECUTE ON PROCEDURE iqueue.create_funcionario_2 TO "G_',user_name,'"@"%"');
				PREPARE stmt1 FROM @sql;
				EXECUTE stmt1;
				DEALLOCATE PREPARE stmt1;
				FLUSH PRIVILEGES;

				set @sql = concat('GRANT EXECUTE ON PROCEDURE iqueue.funcionario_REMOVE_id TO "G_',user_name,'"@"%"');
				PREPARE stmt1 FROM @sql;
				EXECUTE stmt1;
				DEALLOCATE PREPARE stmt1;
				FLUSH PRIVILEGES;
			
            END $$

 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
									PROCEDURES »»»»»»»»» GERENTE »» GRANTS -> "REMOVE" && REVOKE && CREATE FUNCIONARIO
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
 			
		DELIMITER $$
            DROP PROCEDURE IF EXISTS `gerente_REMOVE` $$
			CREATE PROCEDURE `gerente_REMOVE`()
            BEGIN
				DECLARE gerente_id_2 VARCHAR(45);
                DECLARE n INT DEFAULT 0;
				DECLARE i INT DEFAULT 0;
                DECLARE procedureName VARCHAR(45);
                DECLARE user_name VARCHAR(45);

                 DECLARE utilizador_id_3 VARCHAR(45);
                -- DECLARE utilizador_id_4 INT;
				
                SELECT USER() INTO utilizador_id_3;
				SELECT SUBSTRING_INDEX(utilizador_id_3, '@', 1) INTO utilizador_id_3;
				-- SELECT MAX(id),  INTO utilizador_id_4 FROM Funcionario WHERE nr_telemovel = utilizador_id_3;
                IF(utilizador_id_3 != 'grupo2' AND utilizador_id_3 NOT LIKE 'G_%') 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;

                
                CREATE TEMPORARY TABLE tabela_temp engine=memory SELECT ROUTINE_NAME AS proc_name FROM INFORMATION_SCHEMA.ROUTINES WHERE (ROUTINE_TYPE = 'PROCEDURE' AND (ROUTINE_NAME LIKE 'gerente_%' OR ROUTINE_NAME LIKE 'estatistica_%'));
				SELECT COUNT(*) FROM tabela_temp INTO n;
                
                /* Camada extra de segurança - garante que não deixa alterar permissoes que não sejam as suas */
				
				SELECT SUBSTR(gerente_id_2, 3, 20) INTO user_name;
                
				SET i=0;
				WHILE i<n DO 
					SELECT proc_name INTO procedureName FROM tabela_temp LIMIT i,1;
                    
					set @sql = concat('REVOKE EXECUTE ON PROCEDURE iqueue.',procedureName,' FROM "G_',user_name,'"@"%"');
					PREPARE stmt1 FROM @sql;
					EXECUTE stmt1;
					DEALLOCATE PREPARE stmt1;
                  
					SET i = i + 1;
				END WHILE;
                
                DROP TEMPORARY TABLE IF EXISTS tabela_temp;
                CREATE TEMPORARY TABLE tabela_temp engine=memory SELECT ROUTINE_NAME AS func_name FROM INFORMATION_SCHEMA.ROUTINES WHERE (ROUTINE_TYPE = 'FUNCTION' AND ROUTINE_NAME LIKE 'gerente_%');
				SELECT COUNT(*) FROM tabela_temp INTO n;
                
                SET i=0;
				WHILE i<n DO 
					SELECT func_name INTO procedureName FROM tabela_temp LIMIT i,1;
                    
					set @sql = concat('REVOKE EXECUTE ON FUNCTION iqueue.',procedureName,' FROM "G_',user_name,'"@"%"');
					PREPARE stmt1 FROM @sql;
					EXECUTE stmt1;
					DEALLOCATE PREPARE stmt1;
                  
					SET i = i + 1;
				END WHILE;
                
				FLUSH PRIVILEGES;
    			
				set @sql = concat('DROP USER "G_',user_name,'"@"%"');
				PREPARE stmt1 FROM @sql;
				EXECUTE stmt1;
				DEALLOCATE PREPARE stmt1;
                
				DROP TEMPORARY TABLE IF EXISTS tabela_temp;

				set @sql = concat('REVOKE EXECUTE ON PROCEDURE iqueue.funcionario_atender_ticket FROM "G_',user_name,'"@"%"');
				PREPARE stmt1 FROM @sql;
				EXECUTE stmt1;
				DEALLOCATE PREPARE stmt1;
				FLUSH PRIVILEGES;
				
                set @sql = concat('REVOKE EXECUTE ON PROCEDURE iqueue.funcionario_REMOVE_id FROM "G_',user_name,'"@"%"');
				PREPARE stmt1 FROM @sql;
				EXECUTE stmt1;
				DEALLOCATE PREPARE stmt1;
				FLUSH PRIVILEGES;
                
                set @sql = concat('REVOKE EXECUTE ON PROCEDURE iqueue.create_funcionario FROM "G_',user_name,'"@"%"');
				PREPARE stmt1 FROM @sql;
				EXECUTE stmt1;
				DEALLOCATE PREPARE stmt1;
				FLUSH PRIVILEGES;
                
                set @sql = concat('REVOKE EXECUTE ON PROCEDURE iqueue.create_funcionario_2 FROM "G_',user_name,'"@"%"');
				PREPARE stmt1 FROM @sql;
				EXECUTE stmt1;
				DEALLOCATE PREPARE stmt1;
				FLUSH PRIVILEGES;


            END $$

 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
										PROCEDURES »»»»»»»»» GERENTE »» SERVICO »» GET REPUTACAO
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
 DELIMITER $$
			DROP PROCEDURE IF EXISTS `gerente_get_servico_reputacao` $$
			CREATE PROCEDURE `gerente_get_servico_reputacao`()
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE gerente_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _gerente_id INT;
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

				SELECT USER() INTO gerente_id_2;
				SELECT SUBSTRING_INDEX(gerente_id_2, '@', 1) INTO gerente_id_2;

				SELECT SUBSTRING_INDEX(gerente_id_2, '_', 1) INTO role;
				SELECT SUBSTR(gerente_id_2, 3, 20) INTO gerente_id_2;

				SELECT MAX(id) INTO _gerente_id FROM Gerente WHERE nr_telemovel = gerente_id_2;
				IF(role != 'G') 
					THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;

                SELECT servico_id INTO _servico_id FROM Gerente WHERE id = _gerente_id;

                START TRANSACTION;
                
                Select reputacao_min from Servico WHERE id = _servico_id;
                
                COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`get_servico_reputacao` TO 'gerente';
            -- FLUSH PRIVILEGES;
 