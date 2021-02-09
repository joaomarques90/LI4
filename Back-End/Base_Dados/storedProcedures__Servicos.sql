
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
												PROCEDURES »»»»»»»»» SERVICOS
****************************************************************************************************************************
****************************************************************************************************************************
*/

/* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
											PROCEDURES »»»»»»»»» SERVICOS »» GET -> ALL
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
			DROP PROCEDURE IF EXISTS `servicos_get_All` $$
			CREATE PROCEDURE `servicos_get_All`()
			BEGIN

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

			   SELECT * FROM Servico ORDER BY nome;

			   COMMIT;

			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`servicos_get_All` TO guestDB, utilizador;
            -- FLUSH PRIVILEGES;

/* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
											PROCEDURES »»»»»»»»» SERVICOS »» GET -> BY NAME
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
			DROP PROCEDURE IF EXISTS `servicos_get_name` $$
			CREATE PROCEDURE `servicos_get_name`(`_name` VARCHAR(45))
			BEGIN

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

				set @sql = concat('SELECT * FROM Servico WHERE nome LIKE "%',_name,'%" ORDER BY nome ASC');
				PREPARE stmt1 FROM @sql;
				EXECUTE stmt1;
				DEALLOCATE PREPARE stmt1;

				COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`servicos_get_name` TO guestDB, utilizador;
            -- FLUSH PRIVILEGES;

/* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
											PROCEDURES »»»»»»»»» SERVICOS »» GET -> ALL CATEGORY
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
			DROP PROCEDURE IF EXISTS `servicos_get_All_category` $$
			CREATE PROCEDURE `servicos_get_All_category`()
			BEGIN
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

			   SELECT DISTINCT categoria FROM SERVICO ORDER BY categoria ASC;

			   	COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`servicos_get_All_category` TO guestDB, utilizador;
            -- FLUSH PRIVILEGES;

/* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
											PROCEDURES »»»»»»»»» SERVICOS »» GET -> BY CATEGORY
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
			DROP PROCEDURE IF EXISTS `servicos_get_name_category` $$
			CREATE PROCEDURE `servicos_get_name_category`(`_name` VARCHAR(45))
			BEGIN
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

				set @sql = concat('SELECT * FROM Servico WHERE categoria LIKE "%',_name,'%" ORDER BY nome ASC');
				PREPARE stmt1 FROM @sql;
				EXECUTE stmt1;
				DEALLOCATE PREPARE stmt1;

				COMMIT;
                
			   -- SELECT * FROM Servico WHERE categoria LIKE '%{$_name}%' ORDER BY nome ASC;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`servicos_get_name_category` TO guestDB, utilizador;
            -- FLUSH PRIVILEGES;

/* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
											PROCEDURES »»»»»»»»» SERVICOS »» GET -> ALL Locations
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
			DROP PROCEDURE IF EXISTS `servicos_get_all_locations` $$
			CREATE PROCEDURE `servicos_get_all_locations`()
			BEGIN
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

			   SELECT DISTINCT localizacao FROM Servico WHERE localizacao IS NOT NULL ORDER BY localizacao ASC;

			   COMMIT;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`servicos_get_all_locations` TO guestDB, utilizador;
            -- FLUSH PRIVILEGES;
            
/* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
											PROCEDURES »»»»»»»»» SERVICOS »» GET -> BY Location
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
			DROP PROCEDURE IF EXISTS `servicos_get_name_location` $$
			CREATE PROCEDURE `servicos_get_name_location`(`_name` VARCHAR(45))
			BEGIN

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

				set @sql = concat('SELECT * FROM Servico WHERE localizacao IS NOT NULL AND localizacao LIKE "%',_name,'%" ORDER BY nome ASC');
				PREPARE stmt1 FROM @sql;
				EXECUTE stmt1;
				DEALLOCATE PREPARE stmt1;

				COMMIT;
                
			    -- SELECT * FROM Servico WHERE localizacao IS NOT NULL AND localizacao LIKE '%{$_name}%' ORDER BY nome ASC;
			END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`servicos_get_name_location` TO guestDB, utilizador;
            -- FLUSH PRIVILEGES;
            

/* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
                                            PROCEDURES »»»»»»»»» SERVICOS »» GET -> Horario
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/
	DELIMITER $$
            DROP PROCEDURE IF EXISTS `servicos_get_horario` $$
            CREATE PROCEDURE `servicos_get_horario`(`servico_id` int)
            BEGIN
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

                SELECT hora_abertura, hora_fecho FROM Servico WHERE id  = servico_id;

                COMMIT;
                
            END$$
            -- GRANT EXECUTE ON PROCEDURE `iqueue`.`servicos_get_horario` TO guestDB, utilizador;
            -- FLUSH PRIVILEGES;
