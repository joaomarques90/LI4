using System;
using System.Data;
using MySql.Data.MySqlClient;

namespace SmartTicket
{
    public class EstatisticaDAO
    {
        // variaveis instancia
        private BD_Connection connection;
        
        // contrutores
        public EstatisticaDAO() {
            connection = new BD_Connection();
        }
        
            
        // gets e sets
        public BD_Connection get_connection() {
            return connection;
        }
        
        public void set_connection(BD_Connection connection) {
            this.connection = connection;
        }

        // open connection
        public void open_connection()
        {
            connection.open_connection();
        }

        // close connection
        public void close_connection()
        {
            connection.close_connection();
        }

        // funcionalidades

        public Estatistica get_estatistica_tempo_real(int id_servico) {
            Estatistica result = new Estatistica(0,0,0);
            MySqlCommand comm = new MySqlCommand("estatistica_servico_tempo_real", connection.get_connector());
            comm.CommandType = CommandType.StoredProcedure;
            comm.Parameters.AddWithValue("_servico_id", MySqlDbType.Int16).Value = id_servico;
            MySqlDataReader executer;
            executer = comm.ExecuteReader();
            if (!executer.HasRows) ;
            else
            {
                executer.Read();
                int congestao = (int) executer.GetValue(1);
                TimeSpan tempo_espera = (TimeSpan) executer.GetValue(2);
                TimeSpan tempo_atendimento = (TimeSpan) executer.GetValue(3);
                double tempoAtendimento = tempo_atendimento.TotalMinutes;
                double tempoEspera = tempo_espera.TotalMinutes;
                result.set_tempo_espera(tempoEspera);
                result.set_tempo_atendimento(tempoAtendimento);
                result.set_congestao(congestao);
            }
            executer.Dispose();
            executer.Close();
            return result;
        }
        
        public Estatistica get_estatistica_diaria(int id_servico) {
            Estatistica result = new Estatistica(0,0,0);
            MySqlCommand comm = new MySqlCommand("estatistica_servico_diaria", connection.get_connector());
            comm.CommandType = CommandType.StoredProcedure;
            comm.Parameters.AddWithValue("_servico_id", MySqlDbType.Int16).Value = id_servico;
            MySqlDataReader executer;
            executer = comm.ExecuteReader();
            if (!executer.HasRows) ;
            else
            {
                executer.Read();
                TimeSpan tempo_medio_atendimento;
                if (executer.GetValue(4) == DBNull.Value) tempo_medio_atendimento = TimeSpan.Zero;
                else tempo_medio_atendimento = (TimeSpan)executer.GetValue(4);
                TimeSpan tempo_medio_espera;
                if (executer.GetValue(2) == DBNull.Value) tempo_medio_espera = TimeSpan.Zero;
                else tempo_medio_espera = (TimeSpan)executer.GetValue(2);
                Console.WriteLine(tempo_medio_espera.ToString());
                double tempoAtendimento = tempo_medio_atendimento.TotalMinutes;
                double tempoEspera = tempo_medio_espera.TotalMinutes;
                int congestao_media;
                if (executer.GetValue(3) == DBNull.Value) congestao_media = 0;
                else congestao_media = (int)executer.GetValue(3);
                result.set_tempo_espera(tempoEspera);
                result.set_tempo_atendimento(tempoAtendimento);
                result.set_congestao(congestao_media);
            }
            executer.Dispose();
            executer.Close();
            return result;
        }
        
        public Estatistica get_estatistica_semanal(int id_servico) {
            Estatistica result = new Estatistica(0,0,0);
            MySqlCommand comm = new MySqlCommand("estatistica_servico_semanal", connection.get_connector());
            comm.CommandType = CommandType.StoredProcedure;
            comm.Parameters.AddWithValue("_servico_id", MySqlDbType.Int16).Value = id_servico;
            MySqlDataReader executer;
            executer = comm.ExecuteReader();
            if (!executer.HasRows) ;
            else
            {
                executer.Read();
                TimeSpan tempo_medio_atendimento;
                if (executer.GetValue(4) == DBNull.Value) tempo_medio_atendimento = TimeSpan.Zero;
                else tempo_medio_atendimento = (TimeSpan)executer.GetValue(4);
                TimeSpan tempo_medio_espera;
                if (executer.GetValue(2) == DBNull.Value) tempo_medio_espera = TimeSpan.Zero;
                else tempo_medio_espera = (TimeSpan)executer.GetValue(2);
                Console.WriteLine(tempo_medio_espera.ToString());
                double tempoAtendimento = tempo_medio_atendimento.TotalMinutes;
                double tempoEspera = tempo_medio_espera.TotalMinutes;
                int congestao_media;
                if (executer.GetValue(3) == DBNull.Value) congestao_media = 0;
                else congestao_media = (int)executer.GetValue(3);
                result.set_tempo_espera(tempoEspera);
                result.set_tempo_atendimento(tempoAtendimento);
                result.set_congestao(congestao_media);
            }
            executer.Dispose();
            executer.Close();
            return result;
        }
        
        public Estatistica get_estatistica_mensal(int id_servico) {
            Estatistica result = new Estatistica(0,0,0);
            MySqlCommand comm = new MySqlCommand("estatistica_servico_mensal", connection.get_connector());
            comm.CommandType = CommandType.StoredProcedure;
            comm.Parameters.AddWithValue("_servico_id", MySqlDbType.Int16).Value = id_servico;
            MySqlDataReader executer;
            executer = comm.ExecuteReader();
            if (!executer.HasRows) ;
            else
            {
                executer.Read();
                TimeSpan tempo_medio_atendimento;
                if (executer.GetValue(4) == DBNull.Value) tempo_medio_atendimento = TimeSpan.Zero;
                else tempo_medio_atendimento = (TimeSpan)executer.GetValue(4);
                TimeSpan tempo_medio_espera;
                if (executer.GetValue(2) == DBNull.Value) tempo_medio_espera = TimeSpan.Zero;
                else tempo_medio_espera = (TimeSpan)executer.GetValue(2);
                Console.WriteLine(tempo_medio_espera.ToString());
                double tempoAtendimento = tempo_medio_atendimento.TotalMinutes;
                double tempoEspera = tempo_medio_espera.TotalMinutes;
                int congestao_media;
                if (executer.GetValue(3) == DBNull.Value) congestao_media = 0;
                else congestao_media = (int)executer.GetValue(3);
                result.set_tempo_espera(tempoEspera);
                result.set_tempo_atendimento(tempoAtendimento);
                result.set_congestao(congestao_media);
            }
            executer.Dispose();
            executer.Close();
            return result;
        }
    }
    }
