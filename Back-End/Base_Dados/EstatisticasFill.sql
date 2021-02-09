USE iqueue;
SET foreign_key_checks = 0;
-- DELETE FROM Estatistica_Diaria;
TRUNCATE TABLE Estatistica_Diaria;
-- DELETE FROM Estatistica_Semanal;
TRUNCATE TABLE Estatistica_Semanal;
-- DELETE FROM Estatistica_Mensal;
TRUNCATE TABLE Estatistica_Mensal;
SET foreign_key_checks = 1;

 DELIMITER $$ 
 
    DROP PROCEDURE IF EXISTS fill_estatisticas_diaria $$
    CREATE PROCEDURE `fill_estatisticas_diaria`()                       
        BEGIN
                DECLARE n INT DEFAULT 0;
                DECLARE i INT DEFAULT 0;
                DECLARE dia DATE;
                DECLARE _tempo_medio_espera TIME;
                DECLARE _tempo_medio_atendimento TIME;
                DECLARE _congestao INT;
                
                SELECT DATE(MIN(data)) INTO dia FROM Ticket ;
                SET i=1;
                SET n=10;
                WHILE dia <= CURDATE() DO
                    WHILE i<=n DO 
                        SELECT SEC_TO_TIME(AVG(TIME_TO_SEC(tempo_espera))) INTO _tempo_medio_espera FROM Ticket WHERE servico_id = i AND date(data) = dia;
                        SELECT SEC_TO_TIME(AVG(TIME_TO_SEC(tempo_atendimento))) INTO _tempo_medio_atendimento FROM Ticket WHERE servico_id = i AND date(data) = dia;
                        SELECT FLOOR(RAND()*6) INTO _congestao;
                        
                        IF(_tempo_medio_espera IS NOT NULL) THEN INSERT INTO Estatistica_Diaria (data, servico_id, tempo_medio_espera, congestao_media, tempo_atendimento) VALUES (dia, i, _tempo_medio_espera, _congestao, _tempo_medio_atendimento);
                        ELSE IF (SELECT estado FROM Servico WHERE id = i) THEN
								INSERT INTO Estatistica_Diaria (data, servico_id, tempo_medio_espera, congestao_media, tempo_atendimento) VALUES (dia, i, '00:00:00', 0, '00:00:00');
                            END IF;
                        END IF;
                        SET i = i + 1;
                    END WHILE;
                    SET dia = date_add(dia, INTERVAL 1 DAY);
                    SET i=1;
                END WHILE;
           END$$

CALL fill_estatisticas_diaria();


 DELIMITER $$ 
    DROP PROCEDURE IF EXISTS fill_estatisticas_semana $$                 
               
    CREATE PROCEDURE `fill_estatisticas_semana`()                       
        BEGIN
                DECLARE n INT DEFAULT 0;
                DECLARE i INT DEFAULT 0;
                DECLARE dia DATE;
                DECLARE _tempo_medio_espera TIME;
                DECLARE _tempo_medio_atendimento TIME;
                DECLARE _congestao INT;
                
                SELECT DATE(MIN(data)) INTO dia FROM Ticket ;
                SET i=1;
                SET n=10;
                WHILE dia <= CURDATE() DO
                    WHILE i<=n DO 
                        SELECT SEC_TO_TIME(AVG(TIME_TO_SEC(tempo_espera))) INTO _tempo_medio_espera FROM Ticket WHERE servico_id = i AND date(data) >= dia AND date(data) < date_add(dia, INTERVAL 1 WEEK);
                        SELECT SEC_TO_TIME(AVG(TIME_TO_SEC(tempo_atendimento))) INTO _tempo_medio_atendimento FROM Ticket WHERE servico_id = i AND date(data) >= dia AND date(data) < date_add(dia, INTERVAL 1 WEEK);
                        SELECT FLOOR(RAND()*6) INTO _congestao;
                        
                        IF(_tempo_medio_espera IS NOT NULL) THEN 
							INSERT INTO Estatistica_Semanal (data, servico_id, tempo_medio_espera, congestao_media, tempo_atendimento) VALUES (dia, i, _tempo_medio_espera, _congestao, _tempo_medio_atendimento); 
                        ELSE IF (SELECT estado FROM Servico WHERE id = i) THEN
								INSERT INTO Estatistica_Semanal (data, servico_id, tempo_medio_espera, congestao_media, tempo_atendimento) VALUES (dia, i, '00:00:00', 0, '00:00:00');
                            END IF;
                        END IF;
                        SET i = i + 1;
                    END WHILE;
                    SET dia = date_add(dia, INTERVAL 1 WEEK);
                    SET i=1;
                END WHILE;
           END$$

CALL fill_estatisticas_semana();


 DELIMITER $$ 
    DROP PROCEDURE IF EXISTS fill_estatisticas_mensal $$ 
    CREATE PROCEDURE `fill_estatisticas_mensal`()                       
        BEGIN
                DECLARE n INT DEFAULT 0;
                DECLARE i INT DEFAULT 0;
                DECLARE dia DATE;
                DECLARE _tempo_medio_espera TIME;
                DECLARE _tempo_medio_atendimento TIME;
                DECLARE _congestao INT;
                
                SELECT DATE(MIN(data)) INTO dia FROM Ticket ;
                SET i=1;
                SET n=10;
                WHILE dia <= CURDATE() DO
                    WHILE i<=n DO 
                        SELECT SEC_TO_TIME(AVG(TIME_TO_SEC(tempo_espera))) INTO _tempo_medio_espera FROM Ticket WHERE servico_id = i AND date(data) >= dia AND date(data) < date_add(dia, INTERVAL 1 MONTH);
                        SELECT SEC_TO_TIME(AVG(TIME_TO_SEC(tempo_atendimento))) INTO _tempo_medio_atendimento FROM Ticket WHERE servico_id = i AND date(data) >= dia AND date(data) < date_add(dia, INTERVAL 1 MONTH);
                        SELECT FLOOR(RAND()*6) INTO _congestao;
                        
                        IF(_tempo_medio_espera IS NOT NULL) THEN INSERT INTO Estatistica_Mensal (data, servico_id, tempo_medio_espera, congestao_media, tempo_atendimento) VALUES (dia, i, _tempo_medio_espera, _congestao, _tempo_medio_atendimento);
                         ELSE IF(SELECT estado FROM Servico WHERE id = i) THEN
								INSERT INTO Estatistica_Mensal (data, servico_id, tempo_medio_espera, congestao_media, tempo_atendimento) VALUES (dia, i, '00:00:00', 0, '00:00:00');
                            END IF;
                        END IF;
                        SET i = i + 1;
                    END WHILE;
                    SET dia = date_add(dia, INTERVAL 1 MONTH);
                    SET i=1;
                END WHILE;
           END$$

CALL fill_estatisticas_mensal();

CALL myeventEstatisticaRealHoraria;

DROP PROCEDURE IF EXISTS fill_estatisticas_diaria; 
DROP PROCEDURE IF EXISTS fill_estatisticas_semana; 
DROP PROCEDURE IF EXISTS fill_estatisticas_mensal; 