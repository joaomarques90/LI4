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
										FUNCTIONS »»»»»»»»» GUEST »» Check User
****************************************************************************************************************************
****************************************************************************************************************************	
 */
			DROP FUNCTION IF EXISTS `user_exists` $$
			CREATE FUNCTION user_exists(user_name VARCHAR(45), role CHAR) -- role MAIUSCULA
			RETURNS BOOLEAN
			NOT DETERMINISTIC
			BEGIN
                
                DECLARE utilizador_id_3 VARCHAR(45);
                DECLARE resultado BOOLEAN DEFAULT FALSE;
				
                SELECT USER() INTO utilizador_id_3;
				SELECT SUBSTRING_INDEX(utilizador_id_3, '@', 1) INTO utilizador_id_3;

                IF(utilizador_id_3 != 'grupo2' AND utilizador_id_3 != 'guestDB') 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;

                SET utilizador_id_3 = concat(role,'_',user_name);
                
				SELECT user INTO utilizador_id_3 FROM mysql.user WHERE user = utilizador_id_3;

				IF(utilizador_id_3 IS NOT NULL) THEN SET resultado = TRUE; 
				END IF;
				
				RETURN (resultado);
			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`user_exists` TO 'guest';
            -- FLUSH PRIVILEGES;
      