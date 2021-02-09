
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
										FUNCTIONS »»»»»»»»» PROCEDURES »»»»»»  UTILIZADOR »» Dados
****************************************************************************************************************************
****************************************************************************************************************************	
 */	
			DROP PROCEDURE IF EXISTS `utilizador_reputacao` $$
			CREATE PROCEDURE utilizador_reputacao() 
			-- RETURNS FLOAT(4)
			-- NOT DETERMINISTIC
			BEGIN
				/* Camada extra de segurança - garante que não deixa criar tickets para outros utilizadores que não o próprio
						» protege os dados/servidor se a máquina-cliente for atacada
                
					Exemplo -> o backend/frontend foi atacado/alterado, enviando um utilizador_id/telefone diferente da conexão como argumento da procedure 
						Solução -> remover esse argumento, trabalhando sobre a conexão em si para identificar o remetente (que é em SSL e codificação hash 256 para password)
                    
                    Nota - não impede de o utilizador ou atacante de invocar várias vezes a procedure
						Solução - Apenas podemos limitar o nº de tickets_em_espera/hora
                */
				-- DECLARE reputacao FLOAT(4);
				DECLARE utilizador_id_2 VARCHAR(45);
				DECLARE utilizador_id INT;
				DECLARE role VARCHAR(45) DEFAULT NULL;

				SELECT USER() INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '@', 1) INTO utilizador_id_2;

				SELECT SUBSTRING_INDEX(utilizador_id_2, '_', 1) INTO role;
				SELECT SUBSTR(utilizador_id_2, 3, 20) INTO utilizador_id_2;

				IF(role IS NULL OR role != 'U') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;				

				SELECT MAX(id) INTO utilizador_id FROM Utilizador WHERE nr_telemovel = utilizador_id_2;
				SELECT reputacao FROM Utilizador WHERE id = utilizador_id;

			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`utilizador_reputacao` TO 'utilizador';
            -- FLUSH PRIVILEGES;
            
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/            
            DROP PROCEDURE IF EXISTS `utilizador_id` $$
            CREATE PROCEDURE utilizador_id() 
			-- RETURNS INT
			-- NOT DETERMINISTIC
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE reputacao FLOAT(4);
				DECLARE utilizador_id_2 VARCHAR(45);
				-- DECLARE utilizador_id INT;
				DECLARE role VARCHAR(45) DEFAULT NULL;

				SELECT USER() INTO utilizador_id_2;
				SELECT SUBSTRING_INDEX(utilizador_id_2, '@', 1) INTO utilizador_id_2;

				SELECT SUBSTRING_INDEX(utilizador_id_2, '_', 1) INTO role;
				SELECT SUBSTR(utilizador_id_2, 3, 20) INTO utilizador_id_2;

				IF(role IS NULL OR role != 'U') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;				

				SELECT MAX(id) FROM Utilizador WHERE nr_telemovel = utilizador_id_2;

				-- RETURN (utilizador_id);
			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`utilizador_id` TO 'utilizador';
            -- FLUSH PRIVILEGES;



/*
****************************************************************************************************************************
****************************************************************************************************************************
										FUNCTIONS »»»»»»»»» PROCEDURES »»»»»»»» FUNCIONARIO »» Dados
****************************************************************************************************************************
****************************************************************************************************************************	
 */
 
	DELIMITER $$
			DROP PROCEDURE IF EXISTS `funcionario_servico` $$
			CREATE PROCEDURE funcionario_servico() 
			-- RETURNS INT
			-- NOT DETERMINISTIC
			BEGIN
				/* Camada extra de segurança - garante que não deixa criar tickets para outros utilizadores que não o próprio
						» protege os dados/servidor se a máquina-cliente for atacada
                
					Exemplo -> o backend/frontend foi atacado/alterado, enviando um utilizador_id/telefone diferente da conexão como argumento da procedure 
						Solução -> remover esse argumento, trabalhando sobre a conexão em si para identificar o remetente (que é em SSL e codificação hash 256 para password)
                    
                    Nota - não impede de o utilizador ou atacante de invocar várias vezes a procedure
						Solução - Apenas podemos limitar o nº de tickets_em_espera/hora
                */
				DECLARE servico INT;
				DECLARE funcionario_id_2 VARCHAR(45);
				DECLARE _funcionario_id INT;
                DECLARE role VARCHAR(45) DEFAULT NULL;
                
				SELECT USER() INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '@', 1) INTO funcionario_id_2;

				SELECT SUBSTRING_INDEX(funcionario_id_2, '_', 1) INTO role;
				SELECT SUBSTR(funcionario_id_2, 3, 20) INTO funcionario_id_2;

				IF(role IS NULL OR role != 'F') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;	

				SELECT MAX(id) INTO _funcionario_id FROM Funcionario WHERE nr_telemovel = funcionario_id_2;
							
				SELECT servico_id FROM Funcionario WHERE id = _funcionario_id;
				-- RETURN (servico);
			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`funcionario_servico` TO 'funcionario';
            -- FLUSH PRIVILEGES;
            
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/            
	DELIMITER $$
            DROP PROCEDURE IF EXISTS `funcionario_id` $$
            CREATE PROCEDURE funcionario_id() 
			-- RETURNS INT
			-- NOT DETERMINISTIC
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE funcionario_id_2 VARCHAR(45);
				DECLARE _funcionario_id INT;
                DECLARE role VARCHAR(45) DEFAULT NULL;
                
				SELECT USER() INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '@', 1) INTO funcionario_id_2;

				SELECT SUBSTRING_INDEX(funcionario_id_2, '_', 1) INTO role;
				SELECT SUBSTR(funcionario_id_2, 3, 20) INTO funcionario_id_2;

				IF(role IS NULL OR role != 'F') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;	

				SELECT MAX(id) FROM Funcionario WHERE nr_telemovel = funcionario_id_2;

				-- RETURN (funcionario_id);
			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`funcionario_id` TO 'funcionario';
            -- FLUSH PRIVILEGES;
            
            
/*
****************************************************************************************************************************
****************************************************************************************************************************
										FUNCTIONS »»»»»»»»» PROCEDURES »»»»»»»»» FUNCIONARIO/GERENTE »» Ticket
****************************************************************************************************************************
****************************************************************************************************************************	
 */
 
            DROP PROCEDURE IF EXISTS `funcionario_tickets_atender` $$
            CREATE PROCEDURE funcionario_tickets_atender() 
			-- RETURNS INT
			-- NOT DETERMINISTIC
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE funcionario_id_2 VARCHAR(45);
				DECLARE _funcionario_id INT;
                -- DECLARE ticket_id INT DEFAULT -1;
                
                DECLARE role VARCHAR(45) DEFAULT NULL;
                
				SELECT USER() INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '@', 1) INTO funcionario_id_2;

				SELECT SUBSTRING_INDEX(funcionario_id_2, '_', 1) INTO role;
				SELECT SUBSTR(funcionario_id_2, 3, 20) INTO funcionario_id_2;

				IF(role IS NULL OR role != 'F') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;	

				SELECT MAX(id) INTO _funcionario_id FROM Funcionario WHERE nr_telemovel = funcionario_id_2;
                
				IF EXISTS (
						SELECT id FROM Ticket
							WHERE DATE(T.data) = DATE(NOW()) AND 
								  funcionario_id = _funcionario_id AND estado = 'Em Espera' AND 
                                  tempo_espera IS NULL
						  ) 
					THEN 
						SELECT id FROM Ticket
							WHERE DATE(data) = DATE(NOW()) AND 
								  funcionario_id = _funcionario_id AND estado = 'Em Espera' AND 
                                  tempo_espera IS NULL;
				END IF;
				
                -- RETURN (ticket_id);
			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`funcionario_tickets_atender` TO 'funcionario';
            -- FLUSH PRIVILEGES;
            
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/    
            
            DROP PROCEDURE IF EXISTS `funcionario_tickets_anual` $$
            CREATE PROCEDURE funcionario_tickets_anual() 
			-- RETURNS INT
			-- NOT DETERMINISTIC
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE funcionario_id_2 VARCHAR(45);
				DECLARE _funcionario_id INT;
                -- DECLARE resultado INT DEFAULT 0;
                DECLARE role VARCHAR(45) DEFAULT NULL;
                
				SELECT USER() INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '@', 1) INTO funcionario_id_2;

				SELECT SUBSTRING_INDEX(funcionario_id_2, '_', 1) INTO role;
				SELECT SUBSTR(funcionario_id_2, 3, 20) INTO funcionario_id_2;

				IF(role IS NULL OR role != 'F') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;	

				SELECT MAX(id) INTO _funcionario_id FROM Funcionario WHERE nr_telemovel = funcionario_id_2;
                SELECT (COUNT(id)) FROM Ticket 
                    WHERE 
						funcionario_id = _funcionario_id AND
                        DATE(data) = DATE(NOW());
                        
				-- RETURN (resultado);
			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`funcionario_tickets_anual` TO 'funcionario';
            -- FLUSH PRIVILEGES;
            
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/    

            DROP PROCEDURE IF EXISTS `funcionario_tickets_mensal` $$
            CREATE PROCEDURE funcionario_tickets_mensal() 
			-- RETURNS INT
			-- NOT DETERMINISTIC
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE funcionario_id_2 VARCHAR(45);
				DECLARE _funcionario_id INT;
               -- DECLARE resultado INT DEFAULT 0;
                
				SELECT USER() INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '@', 1) INTO funcionario_id_2;
				SELECT MAX(id) INTO _funcionario_id FROM Funcionario WHERE nr_telemovel = funcionario_id_2;
                SELECT (COUNT(id)) FROM Ticket 
                    WHERE 
						funcionario_id = _funcionario_id AND
                        (data BETWEEN (CURDATE() - INTERVAL 1 MONTH) AND CURDATE());
                        
				-- RETURN (resultado);
			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`funcionario_tickets_mensal` TO 'funcionario';
            -- FLUSH PRIVILEGES;


 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/    

            DROP PROCEDURE IF EXISTS `funcionario_tickets_semanal` $$
            CREATE PROCEDURE funcionario_tickets_semanal() 
			-- RETURNS INT
			-- NOT DETERMINISTIC
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE funcionario_id_2 VARCHAR(45);
				DECLARE _funcionario_id INT;
                -- DECLARE resultado INT DEFAULT 0;
                DECLARE role VARCHAR(45) DEFAULT NULL;
                
				SELECT USER() INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '@', 1) INTO funcionario_id_2;

				SELECT SUBSTRING_INDEX(funcionario_id_2, '_', 1) INTO role;
				SELECT SUBSTR(funcionario_id_2, 3, 20) INTO funcionario_id_2;

				IF(role IS NULL OR role != 'F') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;	

				SELECT MAX(id) INTO _funcionario_id FROM Funcionario WHERE nr_telemovel = funcionario_id_2;

                SELECT (COUNT(id)) FROM Ticket 
                    WHERE 
						funcionario_id = _funcionario_id AND
                        (data BETWEEN (CURDATE() - INTERVAL 1 WEEK) AND CURDATE());
                        
				-- RETURN (resultado);
			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`funcionario_tickets_semanal` TO 'funcionario';
            -- FLUSH PRIVILEGES;
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/    

            DROP PROCEDURE IF EXISTS `funcionario_tickets_dia` $$
            CREATE PROCEDURE funcionario_tickets_dia() 
			-- RETURNS INT
			-- NOT DETERMINISTIC
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE funcionario_id_2 VARCHAR(45);
				DECLARE _funcionario_id INT;
                -- DECLARE resultado INT DEFAULT 0;
                DECLARE role VARCHAR(45) DEFAULT NULL;
                
				SELECT USER() INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '@', 1) INTO funcionario_id_2;

				SELECT SUBSTRING_INDEX(funcionario_id_2, '_', 1) INTO role;
				SELECT SUBSTR(funcionario_id_2, 3, 20) INTO funcionario_id_2;

				IF(role IS NULL OR role != 'F') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;	

				SELECT MAX(id) INTO _funcionario_id FROM Funcionario WHERE nr_telemovel = funcionario_id_2;

                SELECT (COUNT(id)) FROM Ticket 
                    WHERE 
						funcionario_id = _funcionario_id AND
                        DATE(data) = DATE(NOW());
                        
				-- RETURN (resultado);
			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`funcionario_tickets_dia` TO 'funcionario';
            -- FLUSH PRIVILEGES;
            

/*
****************************************************************************************************************************
****************************************************************************************************************************
										FUNCTIONS »»»»»»»»» PROCEDURES »»»»»»»»»»» GERENTE »» Dados
****************************************************************************************************************************
****************************************************************************************************************************	
 */
 
 DELIMITER $$
			DROP PROCEDURE IF EXISTS `gerente_servico` $$
			CREATE PROCEDURE gerente_servico() 
			-- RETURNS INT
			-- NOT DETERMINISTIC
			BEGIN
				/* Camada extra de segurança - garante que não deixa criar tickets para outros utilizadores que não o próprio
						» protege os dados/servidor se a máquina-cliente for atacada
                
					Exemplo -> o backend/frontend foi atacado/alterado, enviando um utilizador_id/telefone diferente da conexão como argumento da procedure 
						Solução -> remover esse argumento, trabalhando sobre a conexão em si para identificar o remetente (que é em SSL e codificação hash 256 para password)
                    
                    Nota - não impede de o utilizador ou atacante de invocar várias vezes a procedure
						Solução - Apenas podemos limitar o nº de tickets_em_espera/hora
                */
				-- DECLARE servico INT;
				DECLARE gerente_id_2 VARCHAR(45);
				DECLARE gerente_id INT;
				DECLARE role VARCHAR(45) DEFAULT NULL;
				DECLARE _servico_id INT;


				SELECT USER() INTO gerente_id_2;
				SELECT SUBSTRING_INDEX(gerente_id_2, '@', 1) INTO gerente_id_2;

				SELECT SUBSTRING_INDEX(gerente_id_2, '_', 1) INTO role;
				SELECT SUBSTR(gerente_id_2, 3, 20) INTO gerente_id_2;

				IF(role IS NULL OR role != 'G') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;	

				SELECT MAX(id) INTO gerente_id FROM Gerente WHERE nr_telemovel = gerente_id_2;

				IF(gerente_id IS NULL) 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;
							
				SELECT servico_id INTO _servico_id FROM Gerente WHERE id = gerente_id;
				SELECT * FROM Servico WHERE id = _servico_id;
				-- RETURN (servico);

			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`gerente_servico` TO 'gerente';
            -- FLUSH PRIVILEGES;
            
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/            
            
            DROP PROCEDURE IF EXISTS `gerente_id` $$
            CREATE PROCEDURE gerente_id() 
			-- RETURNS INT
			-- NOT DETERMINISTIC
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE servico INT;
				DECLARE gerente_id_2 VARCHAR(45);
				DECLARE gerente_id INT;
				DECLARE role VARCHAR(45) DEFAULT NULL;


				SELECT USER() INTO gerente_id_2;
				SELECT SUBSTRING_INDEX(gerente_id_2, '@', 1) INTO gerente_id_2;

				SELECT SUBSTRING_INDEX(gerente_id_2, '_', 1) INTO role;
				SELECT SUBSTR(gerente_id_2, 3, 20) INTO gerente_id_2;

				IF(role IS NULL OR role != 'G') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;	

				SELECT MAX(id) FROM Gerente WHERE nr_telemovel = gerente_id_2;

				-- RETURN (gerente_id);

			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`gerente_id` TO 'gerente';
            -- FLUSH PRIVILEGES;
            

/*
****************************************************************************************************************************
****************************************************************************************************************************
										FUNCTIONS »»»»»»»»» GERENTE »» Servico
****************************************************************************************************************************
****************************************************************************************************************************	
 */
 
			DROP PROCEDURE IF EXISTS `gerente_servico_estado_status` $$
			CREATE PROCEDURE `gerente_servico_estado_status`()
            -- RETURNS BOOLEAN
			-- NOT DETERMINISTIC
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE gerente_id_2 VARCHAR(45);
				DECLARE _gerente_id INT;
                -- DECLARE _estado BOOLEAN;
                DECLARE _servico_id INT;
                
				DECLARE servico INT;
				DECLARE role VARCHAR(45) DEFAULT NULL;

				SELECT USER() INTO gerente_id_2;
				SELECT SUBSTRING_INDEX(gerente_id_2, '@', 1) INTO gerente_id_2;

				SELECT SUBSTRING_INDEX(gerente_id_2, '_', 1) INTO role;
				SELECT SUBSTR(gerente_id_2, 3, 20) INTO gerente_id_2;

				IF(role IS NULL OR role != 'G') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;	

				SELECT MAX(id) INTO _gerente_id FROM Gerente WHERE nr_telemovel = gerente_id_2;

				IF(_gerente_id IS NULL) 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;

                SELECT servico_id INTO _servico_id FROM Gerente WHERE id = _gerente_id;

                SELECT estado FROM Servico WHERE id = _servico_id;
				
				-- RETURN (_estado);
             
			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`gerente_servico_estado_status` TO 'gerente';
            -- FLUSH PRIVILEGES;


/*
****************************************************************************************************************************
****************************************************************************************************************************
										FUNCTIONS »»»»»»»»» Utilizador »» Ticket
****************************************************************************************************************************
****************************************************************************************************************************	
 */
 
	DELIMITER $$
 
			DROP PROCEDURE IF EXISTS `utilizador_auto_cancela` $$
			CREATE PROCEDURE `utilizador_auto_cancela`(ticketid INT)
            -- RETURNS BOOLEAN
			-- NOT DETERMINISTIC
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE utilizador_id_2 VARCHAR(45);
                DECLARE _utilizador_id INT;
                DECLARE role VARCHAR(45) DEFAULT NULL;

                DECLARE _ticket_id INT;
                DECLARE _estado VARCHAR(45) DEFAULT NULL;
                DECLARE _tempo_espera TIME DEFAULT NULL;

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


                SELECT id 			INTO _ticket_id 		FROM Ticket WHERE id = ticketID;
                SELECT estado  		INTO _estado 		    FROM Ticket WHERE id = _ticket_id;
                SELECT tempo_espera INTO _tempo_espera 	    FROM Ticket WHERE id = _ticket_id;
                
                
                IF(_ticket_id IS NULL) 										 	 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket - ID Nao existente BD';
					ELSE IF(_estado = 'Usado') 								     THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket - Já Usado';
					ELSE IF(_estado = 'Descartado') 						     THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket - Já Descartado';
					ELSE IF(_estado = 'Inutilizado') 						     THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket - Já Inutilizado';
					ELSE IF(_estado = 'Em Espera' AND _tempo_espera IS NOT NULL) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket - Em Utilizacao';
				END IF; END IF; END IF; END IF; END IF;


                UPDATE Ticket 
                		SET observacoes = IFNULL(CONCAT( observacoes , CONCAT("\n AUTO-CANCELATION at ", NOW()) ), CONCAT("AUTO-CANCELATION at ", NOW())),
                		    estado = 'Descartado'
						WHERE id = ticketid;
				
				COMMIT;
			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`auto_cancela` TO 'utilizador';
            -- FLUSH PRIVILEGES;

/* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/            
		DELIMITER $$

            DROP PROCEDURE IF EXISTS `utilizador_ticket_a_frente` $$
            CREATE PROCEDURE utilizador_ticket_a_frente(IN ticket_id INT) 
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE reputacao FLOAT(4);
				DECLARE utilizador_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _utilizador_id INT;
				DECLARE role VARCHAR(45) DEFAULT NULL;
				DECLARE _servico_id INT;
				DECLARE _nr_acesso INT;
				DECLARE res INT;

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
					THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket em estar nao fila espera, blyat';
				END IF;

				SELECT servico_id INTO _servico_id FROM Ticket WHERE id = ticket_id;
				SELECT nr_acesso INTO _nr_acesso FROM Ticket WHERE id = ticket_id;
				
				SELECT COALESCE(-(MIN(nr_acesso)-_nr_acesso), 0) AS tickets_a_frente FROM Ticket
					WHERE 
						servico_id = _servico_id AND
						DATE(data) = DATE(NOW()) AND
						estado = 'Em Espera' AND
						id != ticket_id AND 
						_nr_acesso > nr_acesso;

			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`ticket_a_frente` TO 'utilizador';
            -- FLUSH PRIVILEGES;