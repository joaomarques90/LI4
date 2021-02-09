
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
										FUNCTIONS »»»»»»»»» GERENTE »» Dados
****************************************************************************************************************************
****************************************************************************************************************************	
 */
			DROP FUNCTION IF EXISTS `gerente_servico` $$
			CREATE FUNCTION gerente_servico() 
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
				DECLARE gerente_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE gerente_id INT;
				DECLARE role VARCHAR(45) DEFAULT NULL;


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
							
					SELECT servico_id INTO Servico FROM Gerente WHERE id = gerente_id;
				RETURN (servico);

			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`gerente_servico` TO 'gerente';
            -- FLUSH PRIVILEGES;
            
 /* 
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .
.  .  .  .  .  .  .  .  .  .  .  ..........................................................  .  .  .  .  .  .  .  .  .  .  .
*/            
            
            DROP FUNCTION IF EXISTS `gerente_id` $$
            CREATE FUNCTION gerente_id() 
			RETURNS INT
			NOT DETERMINISTIC
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

				SELECT MAX(id) INTO gerente_id FROM Gerente WHERE nr_telemovel = gerente_id_2;

				IF(gerente_id IS NULL) 
                	THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Executar permissao nao ter blyat';
                END IF;

				RETURN (gerente_id);

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
 
			DROP FUNCTION IF EXISTS `gerente_servico_estado_status` $$
			CREATE FUNCTION `gerente_servico_estado_status`()
            RETURNS BOOLEAN
			NOT DETERMINISTIC
			BEGIN
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				/* Camada extra de segurança - garante que não deixa alterar tickets que não sejam os seus */
				DECLARE gerente_id_2 VARCHAR(45);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
				DECLARE _gerente_id INT;
                DECLARE _estado BOOLEAN;
                
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

                SELECT estado INTO _estado FROM Servico WHERE gerente_id = _gerente_id;
				
				RETURN (_estado);
             
			END$$
            -- GRANT EXECUTE ON FUNCTION `iqueue`.`gerente_servico_estado_status` TO 'gerente';
            -- FLUSH PRIVILEGES;