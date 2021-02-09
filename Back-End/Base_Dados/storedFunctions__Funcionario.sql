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
										FUNCTIONS »»»»»»»»» FUNCIONARIO »» Dados
****************************************************************************************************************************
****************************************************************************************************************************	
 */
			DROP FUNCTION IF EXISTS `funcionario_servico` $$
			CREATE FUNCTION funcionario_servico() 
			RETURNS INT
			NOT DETERMINISTIC
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
							
					SELECT servico_id INTO Servico FROM Funcionario WHERE id = funcionario_id;
				RETURN (servico);
			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`funcionario_servico` TO 'funcionario';
            -- FLUSH PRIVILEGES;
            
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/            
            
            DROP FUNCTION IF EXISTS `funcionario_id` $$
            CREATE FUNCTION funcionario_id() 
			RETURNS INT
			NOT DETERMINISTIC
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

				SELECT MAX(id) INTO _funcionario_id FROM Funcionario WHERE nr_telemovel = funcionario_id_2;

				RETURN (funcionario_id);
			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`funcionario_id` TO 'funcionario';
            -- FLUSH PRIVILEGES;
            
            
/*
****************************************************************************************************************************
****************************************************************************************************************************
										FUNCTIONS »»»»»»»»» FUNCIONARIO/GERENTE »» Ticket
****************************************************************************************************************************
****************************************************************************************************************************	
 */
 
            DROP FUNCTION IF EXISTS `funcionario_tickets_atender` $$
            CREATE FUNCTION funcionario_tickets_atender() 
			RETURNS INT
			NOT DETERMINISTIC
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE funcionario_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _funcionario_id INT;
                DECLARE ticket_id INT DEFAULT -1;
                
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
								  funcionario_id = _funcionario_id AND estado = @ESTADO_1 AND 
                                  tempo_espera IS NULL
						  ) 
					THEN 
						SELECT id INTO ticket_id FROM Ticket
							WHERE DATE(data) = DATE(NOW()) AND 
								  funcionario_id = _funcionario_id AND estado = @ESTADO_1 AND 
                                  tempo_espera IS NULL;
				END IF;
				
                RETURN (ticket_id);
			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`funcionario_tickets_atender` TO 'funcionario';
            -- FLUSH PRIVILEGES;
            
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/    
            
            DROP FUNCTION IF EXISTS `funcionario_tickets_anual` $$
            CREATE FUNCTION funcionario_tickets_anual() 
			RETURNS INT
			NOT DETERMINISTIC
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE funcionario_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _funcionario_id INT;
                DECLARE resultado INT DEFAULT 0;
                DECLARE role VARCHAR(45) DEFAULT NULL;
                
				SELECT USER() INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '@', 1) INTO funcionario_id_2;

				SELECT SUBSTRING_INDEX(funcionario_id_2, '_', 1) INTO role;
				SELECT SUBSTR(funcionario_id_2, 3, 20) INTO funcionario_id_2;

				IF(role IS NULL OR role != 'F') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;	

				SELECT MAX(id) INTO _funcionario_id FROM Funcionario WHERE nr_telemovel = funcionario_id_2;
                SELECT (COUNT(id)) INTO resultado FROM Ticket 
                    WHERE 
						funcionario_id = _funcionario_id AND
                        DATE(data) = DATE(NOW());
                        
				RETURN (resultado);
			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`funcionario_tickets_anual` TO 'funcionario';
            -- FLUSH PRIVILEGES;
            
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/    

             DROP FUNCTION IF EXISTS `funcionario_tickets_mensal` $$
            CREATE FUNCTION funcionario_tickets_mensal() 
			RETURNS INT
			NOT DETERMINISTIC
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE funcionario_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _funcionario_id INT;
                DECLARE resultado INT DEFAULT 0;
                
				SELECT USER() INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '@', 1) INTO funcionario_id_2;
				SELECT MAX(id) INTO _funcionario_id FROM Funcionario WHERE nr_telemovel = funcionario_id_2;
                SELECT (COUNT(id)) INTO resultado FROM Ticket 
                    WHERE 
						funcionario_id = _funcionario_id AND
                        (data BETWEEN (CURDATE() - INTERVAL 1 MONTH) AND CURDATE());
                        
				RETURN (resultado);
			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`funcionario_tickets_mensal` TO 'funcionario';
            -- FLUSH PRIVILEGES;


 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/    

             DROP FUNCTION IF EXISTS `funcionario_tickets_semanal` $$
            CREATE FUNCTION funcionario_tickets_semanal() 
			RETURNS INT
			NOT DETERMINISTIC
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE funcionario_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _funcionario_id INT;
                DECLARE resultado INT DEFAULT 0;
                DECLARE role VARCHAR(45) DEFAULT NULL;
                
				SELECT USER() INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '@', 1) INTO funcionario_id_2;

				SELECT SUBSTRING_INDEX(funcionario_id_2, '_', 1) INTO role;
				SELECT SUBSTR(funcionario_id_2, 3, 20) INTO funcionario_id_2;

				IF(role IS NULL OR role != 'F') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;	

				SELECT MAX(id) INTO _funcionario_id FROM Funcionario WHERE nr_telemovel = funcionario_id_2;

                SELECT (COUNT(id)) INTO resultado FROM Ticket 
                    WHERE 
						funcionario_id = _funcionario_id AND
                        (data BETWEEN (CURDATE() - INTERVAL 1 WEEK) AND CURDATE());
                        
				RETURN (resultado);
			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`funcionario_tickets_semanal` TO 'funcionario';
            -- FLUSH PRIVILEGES;
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/    

            DROP FUNCTION IF EXISTS `funcionario_tickets_dia` $$
            CREATE FUNCTION funcionario_tickets_dia() 
			RETURNS INT
			NOT DETERMINISTIC
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE funcionario_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _funcionario_id INT;
                DECLARE resultado INT DEFAULT 0;
                DECLARE role VARCHAR(45) DEFAULT NULL;
                
				SELECT USER() INTO funcionario_id_2;
				SELECT SUBSTRING_INDEX(funcionario_id_2, '@', 1) INTO funcionario_id_2;

				SELECT SUBSTRING_INDEX(funcionario_id_2, '_', 1) INTO role;
				SELECT SUBSTR(funcionario_id_2, 3, 20) INTO funcionario_id_2;

				IF(role IS NULL OR role != 'F') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
				END IF;	

				SELECT MAX(id) INTO _funcionario_id FROM Funcionario WHERE nr_telemovel = funcionario_id_2;

                SELECT (COUNT(id)) INTO resultado FROM Ticket 
                    WHERE 
						funcionario_id = _funcionario_id AND
                        DATE(data) = DATE(NOW());
                        
				RETURN (resultado);
			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`funcionario_tickets_dia` TO 'funcionario';
            -- FLUSH PRIVILEGES;
            

