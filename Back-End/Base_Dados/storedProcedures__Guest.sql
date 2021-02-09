
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
		-- CREATE ROLE 'utilizador', 'guestDB';
		
		DROP USER IF EXISTS 'guestDB'@'%';
		CREATE USER 'guestDB'@'%';
		-- GRANT 'guestDB' TO 'guestDB'@'localhost';
		-- FLUSH PRIVILEGES;
        
        DELIMITER $$

-- Tem só direito a conectar à BD e criar utilizador(es)

/* 
****************************************************************************************************************************
****************************************************************************************************************************
									 PROCEDURES »»»»»»»»» GUEST »» CREATE UTILIZADOR
****************************************************************************************************************************
****************************************************************************************************************************	
*/

			DROP PROCEDURE IF EXISTS `create_utilizador` $$
			CREATE PROCEDURE `create_utilizador`(`user_name` INT, `passwd` VARCHAR(45))
			BEGIN
				DECLARE utilizador_id_3 VARCHAR(45);

				SELECT USER() INTO utilizador_id_3;
				SELECT SUBSTRING_INDEX(utilizador_id_3, '@', 1) INTO utilizador_id_3;
                IF(utilizador_id_3 NOT LIKE 'guestDB' AND utilizador_id_3 NOT LIKE 'grupo2') 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;

				set @sql =  CONCAT('CREATE USER "U_',user_name,'"@"%" IDENTIFIED WITH mysql_native_password BY "',passwd,'" WITH MAX_USER_CONNECTIONS 2');		  

				PREPARE stmt1 FROM @sql;
				EXECUTE stmt1;
				DEALLOCATE PREPARE stmt1;

				INSERT INTO Utilizador(nr_telemovel, pass) VALUES (user_name, AES_ENCRYPT(passwd, 'UMinho2020Grupo2'));

				CALL utilizadorUPDATE_PRIVILEGIOS(user_name);

			END$$


/*
****************************************************************************************************************************
****************************************************************************************************************************
										FUNCTIONS »»»»»»»»» GUEST »» Check User
****************************************************************************************************************************
****************************************************************************************************************************	
 */
 
	DELIMITER $$
			DROP PROCEDURE IF EXISTS `user_exists` $$
			CREATE PROCEDURE user_exists(user_name VARCHAR(45), role CHAR) -- role MAIUSCULA
			BEGIN
                
                DECLARE utilizador_id_3 VARCHAR(45);
                DECLARE resultado BOOLEAN DEFAULT FALSE;
				
                SELECT USER() INTO utilizador_id_3;
				SELECT SUBSTRING_INDEX(utilizador_id_3, '@', 1) INTO utilizador_id_3;

                IF(utilizador_id_3 != 'grupo2' AND utilizador_id_3 != 'guestDB') 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;

                SET utilizador_id_3 = concat(role,'_',user_name);
                
				SELECT Count(user) INTO resultado FROM mysql.user WHERE user = utilizador_id_3;
                
                IF (resultado > 0) THEN SET resultado = TRUE; END IF;
				
				SELECT resultado;
			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`user_exists` TO 'guest';
            -- FLUSH PRIVILEGES;
      

/* 
****************************************************************************************************************************
****************************************************************************************************************************
									 PROCEDURES »»»»»»»»» GUEST »» GRANTS
****************************************************************************************************************************
****************************************************************************************************************************	
*/ 		
            GRANT EXECUTE ON PROCEDURE iqueue.create_utilizador TO 'guestDB'@'%';
            GRANT EXECUTE ON PROCEDURE iqueue.user_exists TO 'guestDB'@'%';
            -- GRANT EXECUTE ON PROCEDURE iqueue.user_exists_2 TO 'guestDB'@'%';
            
            FLUSH PRIVILEGES;

