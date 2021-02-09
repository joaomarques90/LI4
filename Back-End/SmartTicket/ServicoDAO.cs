using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using MySql.Data.MySqlClient;
using SmartTicket;

namespace SmartTicket
{
    public class ServicoDAO
    {
        // variaveis instancia
        
        private BD_Connection connection;
        
        // construtores
        public ServicoDAO(){
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
        public void open_connection(){
            connection.open_connection();
        }

        // close connection
        public void close_connection() {
            connection.close_connection();
        }

        // funcionalidades 
        
        // método que retorna lista de todos os serviços da app
        public List<Servico> get_servicos() {
            List<Servico> result = new List<Servico>();
            MySqlCommand comm = new MySqlCommand("iqueue.servicos_get_All",connection.get_connector());
            comm.CommandType = CommandType.StoredProcedure;
            MySqlDataReader executer;
            executer = comm.ExecuteReader();
            
            if (!executer.HasRows) ;
            else {
                while (executer.Read()) {
                    int id = (int) executer.GetValue(0);
                    string nome = (string) executer.GetValue(1);
                    string categoria = (string) executer.GetValue(2);
                    Boolean estado = (Boolean) executer.GetValue(3);
                    TimeSpan horaAbertura = (TimeSpan) executer.GetValue(4);
                    TimeSpan horaFecho = (TimeSpan) executer.GetValue(5);
                    double latitude = (double) executer.GetValue(6);
                    double longitude = (double) executer.GetValue(7);
                    string localizacao = (string) executer.GetValue(8);
                    float reputacaoMinima = (float) executer.GetValue(9);
                    int ticketAtual;
                    if (executer.GetValue(10) == DBNull.Value) ticketAtual = 0; else ticketAtual = (int) executer.GetValue(10);
                    string email = (string) executer.GetValue(11);
                    string numero = ((int) executer.GetValue(12)).ToString();
                    Servico s = new Servico( id,  nome,  localizacao,  latitude,  longitude, email , numero,  horaAbertura,  horaFecho,  estado,  reputacaoMinima,  ticketAtual,  categoria);
                    result.Add(s);
                }
                executer.Dispose();
                executer.Close();
            }
            return result;
        }
        
         // método que devolve serviços que depois de efetuar procura por uma palavra-chave 
        public List<Servico> get_servicos_search(string palavra) {
            DamerauLevenshteinDistance compare = new DamerauLevenshteinDistance();
            List<Servico> result = new List<Servico>();
            MySqlCommand comm = new MySqlCommand("iqueue.servicos_get_All",connection.get_connector());
            comm.CommandType = CommandType.StoredProcedure;
            MySqlDataReader executer;
            executer = comm.ExecuteReader();
            if (!executer.HasRows) ;
            else {
                while (executer.Read()) {
                    int id = (int) executer.GetValue(0);
                    string nome = (string) executer.GetValue(1);
                    string categoria = (string) executer.GetValue(2);
                    Boolean estado = (Boolean) executer.GetValue(3);
                    TimeSpan horaAbertura = (TimeSpan) executer.GetValue(4);
                    TimeSpan horaFecho = (TimeSpan) executer.GetValue(5);
                    double latitude = (double) executer.GetValue(6);
                    double longitude = (double) executer.GetValue(7);
                    string localizacao = (string) executer.GetValue(8);
                    float reputacaoMinima = (float) executer.GetValue(9);
                    int ticketAtual;
                    if (executer.GetValue(10) == DBNull.Value) ticketAtual = 0; else ticketAtual = (int) executer.GetValue(10);
                    string email = (string) executer.GetValue(11);
                    string numero = ((int) executer.GetValue(12)).ToString();
                    string[] aux = new string[3];
                    aux = localizacao.Split(",");
                    int comparator1 = nome.Length / 2 + (nome.Length / 2) /2 ;
                    int comparator2 = aux[2].Length / 2;
                    if ((compare.DamerauLevenshteinDistanceTo(aux[2], palavra) < palavra.Length - (palavra.Length - comparator2)) || (compare.DamerauLevenshteinDistanceTo(nome, palavra) < palavra.Length - (palavra.Length - comparator1))  || id.ToString() == palavra) {
                        Servico s = new Servico( id,  nome,  localizacao,  latitude,  longitude, email , numero,  horaAbertura,  horaFecho,  estado,  reputacaoMinima,  ticketAtual,  categoria);
                        result.Add(s);
                    }
                    else
                    {
                        string[] aux2 = nome.Split(" ");
                        if (aux2[0] != null) {
                            if (compare.DamerauLevenshteinDistanceTo(aux2[0], palavra) < palavra.Length - (palavra.Length - palavra.Length/2)){
                                Servico s = new Servico( id,  nome,  localizacao,  latitude,  longitude, email , numero,  horaAbertura,  horaFecho,  estado,  reputacaoMinima,  ticketAtual,  categoria);
                                result.Add(s);
                            }
                        }
                    }
                }
            }
            executer.Dispose();
            executer.Close();
            
            return result;
        }
        
        // métodos relacionados com a filtragem por categoria

        // devolve lista de categorias para apresentar ao utilizador as possibilidades
        public List<string> get_categorias() {
            List<string> result = new List<string>();
            MySqlCommand comm = new MySqlCommand("servicos_get_All_category",connection.get_connector());
            comm.CommandType = CommandType.StoredProcedure;
            MySqlDataReader executer;
            executer = comm.ExecuteReader();
            if (!executer.HasRows) ;
            else {
                while (executer.Read()) {
                    string s = (string)executer.GetValue(0);
                    result.Add(s);
                }
                executer.Dispose();
                executer.Close();
            }
            return result;
        }
        
        // devolve lista de serviços com uma dada categoria
        public List<Servico> get_servicos_categoria(string categoria) {
            List<Servico> result = new List<Servico>();
            MySqlCommand comm = new MySqlCommand("servicos_get_name_category",connection.get_connector());
            comm.CommandType = CommandType.StoredProcedure;
            comm.Parameters.Add("_name", MySqlDbType.VarChar, 45).Value = categoria;
            MySqlDataReader executer;
            executer = comm.ExecuteReader();
            if (!executer.HasRows) ;
            else {
                while (executer.Read()) {
                    int id = (int)executer.GetValue(0);
                    string nome = (string)executer.GetValue(1);
                    Boolean estado = (Boolean)executer.GetValue(3);
                    TimeSpan horaAbertura = (TimeSpan)executer.GetValue(4);
                    TimeSpan horaFecho = (TimeSpan)executer.GetValue(5);
                    double latitude = (double)executer.GetValue(6);
                    double longitude = (double)executer.GetValue(7);
                    string localizacao = (string)executer.GetValue(8);
                    float reputacaoMinima = (float)executer.GetValue(9);
                    int ticketAtual;
                    if (executer.GetValue(10) == DBNull.Value) ticketAtual = 0; else ticketAtual = (int) executer.GetValue(10);
                    string email = (string) executer.GetValue(11);
                    string numero = ((int) executer.GetValue(12)).ToString();
                    Servico s = new Servico(id, nome, localizacao, latitude, longitude, email, numero, horaAbertura, horaFecho, estado, reputacaoMinima, ticketAtual, categoria);
                    result.Add(s);
                }
                executer.Dispose();
                executer.Close();
            }
            return result;
        }
        
        // métodos relacionados com a filtragem por localizacao

        // devolve lista de localizacoes para apresentar ao utilizador as possibilidades (parte sql está mal feita)
        public List<string> get_localizacoes() {
            List<string> result = new List<string>();
            MySqlCommand comm = new MySqlCommand("servicos_get_all_locations",connection.get_connector());
            MySqlDataReader executer;
            executer = comm.ExecuteReader();
            if (!executer.HasRows) ;
            else {
                while (executer.Read()) {
                    string s = (string)executer.GetValue(0);
                    string[] aux = new string[3];
                    aux = s.Split(",");
                    if (!result.Contains(aux[2])) result.Add(aux[2]);
                }
                executer.Dispose();
                executer.Close();
            }
            return result;
        }
// devolve lista de serviços com uma dada localizacao
        public List<Servico> get_servicos_localizacao(string localizacao) {
            List<Servico> result = new List<Servico>();
            MySqlCommand comm = new MySqlCommand("servicos_get_name_location",connection.get_connector());
            comm.CommandType = CommandType.StoredProcedure;
            comm.Parameters.Add("_name", MySqlDbType.VarChar, 45).Value = localizacao;
            MySqlDataReader executer;
            executer = comm.ExecuteReader();
            if (!executer.HasRows) ;
            else {
                while (executer.Read()) {
                    int id = (int)executer.GetValue(0);
                    string nome = (string)executer.GetValue(1);
                    string categoria = (string)executer.GetValue(2);
                    Boolean estado = (Boolean)executer.GetValue(3);
                    TimeSpan horaAbertura = (TimeSpan)executer.GetValue(4);
                    TimeSpan horaFecho = (TimeSpan)executer.GetValue(5);
                    double latitude = (double)executer.GetValue(6);
                    double longitude = (double)executer.GetValue(7);
                    float reputacaoMinima = (float)executer.GetValue(9);
                    int ticketAtual;
                    if (executer.GetValue(10) == DBNull.Value) ticketAtual = 0; else ticketAtual = (int) executer.GetValue(10);
                    string email = (string) executer.GetValue(11);
                    string numero = ((int) executer.GetValue(12)).ToString();
                    Servico s = new Servico(id, nome, localizacao, latitude, longitude, email, numero, horaAbertura, horaFecho, estado, reputacaoMinima, ticketAtual, categoria);
                    result.Add(s);
                }
                executer.Dispose();
                executer.Close();
            }
            return result;
        }
         
        // métodos relacionados com serviços favoritos
        
        // adiciona um serviço como favorito do utilizador
        public void add_servico_favoritos(int id_servico) {
            MySqlCommand comm = new MySqlCommand("utilizador_add_servico_favorito",connection.get_connector());
            comm.CommandType = CommandType.StoredProcedure;
            comm.Parameters.Add("_servico_id", MySqlDbType.Int16).Value = id_servico;
            comm.ExecuteNonQuery();
        }

        // retorna lista de serviços favoritos do utilizador (nao funciona)
        public List<Servico> get_servicos_favoritos() {
            List<Servico> result = new List<Servico>();
            MySqlCommand comm = new MySqlCommand("utilizador_get_servico_favorito",connection.get_connector());
            comm.CommandType = CommandType.StoredProcedure;
            MySqlDataReader executer;
            executer = comm.ExecuteReader();
            if (!executer.HasRows) ;
            else {
                while (executer.Read()) {
                    int id = (int)executer.GetValue(0);
                    string nome = (string)executer.GetValue(1);
                    string categoria = (string)executer.GetValue(2);
                    Boolean estado = (Boolean)executer.GetValue(3);
                    TimeSpan horaAbertura = (TimeSpan)executer.GetValue(4);
                    TimeSpan horaFecho = (TimeSpan)executer.GetValue(5);
                    double latitude = (double)executer.GetValue(6);
                    double longitude = (double)executer.GetValue(7);
                    string localizacao = (string)executer.GetValue(8);
                    float reputacaoMinima = (float)executer.GetValue(9);
                    int ticketAtual;
                    if (executer.GetValue(10) == DBNull.Value) ticketAtual = 0; else ticketAtual = (int) executer.GetValue(10);
                    string email = (string) executer.GetValue(11);
                    string numero = ((int) executer.GetValue(12)).ToString();
                    Servico s = new Servico(id, nome, localizacao, latitude, longitude, email, numero, horaAbertura, horaFecho, estado, reputacaoMinima, ticketAtual, categoria);
                    result.Add(s);
                }
                executer.Dispose();
                executer.Close();
            }
            return result.OrderBy(s=>s.get_nome()).ToList();
        }

        // verifica se um serviço pertence aos favoritos do utilizador
        /*
         * 0 = nao pertence
         * 1 = pertence
         */
        public int contains_servico_favoritos(int id_servico) {
            int result = 0;
            MySqlCommand comm = new MySqlCommand("utilizador_exist_servico_favorito",connection.get_connector());
            comm.CommandType = CommandType.StoredProcedure;
            comm.Parameters.Add("_servico_id", MySqlDbType.Int16).Value = id_servico;
            MySqlDataReader executer;
            executer = comm.ExecuteReader();
            executer.Read();
            if (!executer.HasRows) ;
            else {
                if (executer.GetValue(0) != null) return 1;
            }
            return result;
        }

        // remove servico favorito
        public void remove_servico_favorito(int id_servico) {
            MySqlCommand comm = new MySqlCommand("utilizador_remove_servico_favorito",connection.get_connector());
            comm.CommandType = CommandType.StoredProcedure;
            comm.Parameters.Add("_servico_id", MySqlDbType.Int16).Value = id_servico;
            comm.ExecuteNonQuery();
        }
        // retorna servicos usados no ultimo mes pelo utilizador, ordenados do mais usado para o menos usado (joao: falta segundo metodo)
        public List<Servico> get_servicos_usados_recentemente() {
            List<Servico> result = new List<Servico>();
            MySqlCommand comm = new MySqlCommand("utilizador_servico_mais_usados",connection.get_connector());
            comm.CommandType = CommandType.StoredProcedure;
            MySqlDataReader executer;
            executer = comm.ExecuteReader();
            if (!executer.HasRows) ;
            else {
                while (executer.Read()) {
                    Console.WriteLine("Num cols: "+  executer.FieldCount);
                    int id = (int)executer.GetValue(0);
                    string nome = (string)executer.GetValue(2);
                    string categoria = (string)executer.GetValue(3);
                    Boolean estado = (Boolean)executer.GetValue(4);
                    TimeSpan horaAbertura = (TimeSpan)executer.GetValue(5);
                    TimeSpan horaFecho = (TimeSpan)executer.GetValue(6);
                    double latitude = (double)executer.GetValue(7);
                    double longitude = (double)executer.GetValue(8);
                    string localizacao = (string)executer.GetValue(9);
                    float reputacaoMinima = (float)executer.GetValue(10);
                    int ticketAtual;
                    if (executer.GetValue(11) == DBNull.Value) ticketAtual = 0; else ticketAtual = (int) executer.GetValue(11);
                    string email = (string) executer.GetValue(12);
                    string numero = ((int) executer.GetValue(13)).ToString();
                    Servico s = new Servico(id, nome, localizacao, latitude, longitude, email, numero, horaAbertura, horaFecho, estado, reputacaoMinima, ticketAtual, categoria);
                    result.Add(s);
                }
                executer.Dispose();
                executer.Close();
            }

            return result;
        }
        
        
        // Metodos referentes ao gerente 
        
        // método que obtem classificacao minima serviço
        public float get_classificacao_minima() {
            float result = 0;
            MySqlCommand comm = new MySqlCommand("gerente_get_servico_reputacao",connection.get_connector());
            comm.CommandType = CommandType.StoredProcedure;
            MySqlDataReader executer;
            executer = comm.ExecuteReader();
            executer.Read();
            if (!executer.HasRows) ;
            else {
                result = (float) executer.GetValue(0);
            }
            executer.Dispose();
            executer.Close();
            return result;
        }

        // método que muda classificação minima serviço
        public void set_classificacao_minima(float reputacao_min) {
            MySqlCommand comm = new MySqlCommand("gerente_servico_reputacao",connection.get_connector());
            comm.CommandType = CommandType.StoredProcedure;
            comm.Parameters.Add("_reputacao", MySqlDbType.Float).Value = reputacao_min;
            comm.ExecuteNonQuery();
        }
        
        // método que desativa/ativa funcionalidade retirar tickets 
        
        // método que obtem opcao atual de retirar tickets 
        public Boolean get_funcionalidade_retirar_tickets() {
            Boolean result = false;
            MySqlCommand comm = new MySqlCommand("gerente_servico_estado_status",connection.get_connector());
            comm.CommandType = CommandType.StoredProcedure;
            MySqlDataReader executer;
            executer = comm.ExecuteReader();
            executer.Read();
            if (!executer.HasRows) ;
            else {
                result = (Boolean) executer.GetValue(0);
            }
            executer.Dispose();
            executer.Close();
            return result;
        }

        // método que configura opcao de retirar tickets
        public void set_funcionalidade_retirar_tickets(int r) {
            MySqlCommand comm = new MySqlCommand("gerente_servico_estado",connection.get_connector());
            comm.CommandType = CommandType.StoredProcedure;
            comm.Parameters.Add("_estado", MySqlDbType.Int16).Value = r;
            comm.ExecuteNonQuery();
        }
        
        // método que obtem horário de atendimento
        public Tuple<TimeSpan,TimeSpan> get_horario_atendimento() {
            MySqlCommand comm = new MySqlCommand("gerente_servico_horario",connection.get_connector());
            comm.CommandType = CommandType.StoredProcedure;
            MySqlDataReader executer;
            executer = comm.ExecuteReader();
            executer.Read();
            if (!executer.HasRows) ;
            else {
                TimeSpan horaAbertura = (TimeSpan)executer.GetValue(0);
                TimeSpan horaFecho = (TimeSpan)executer.GetValue(1);
                Tuple<TimeSpan,TimeSpan> result = new Tuple<TimeSpan, TimeSpan>(horaAbertura,horaFecho);
                executer.Dispose();
                executer.Close();
                return result;
            }
            executer.Dispose();
            executer.Close();
            return new Tuple<TimeSpan, TimeSpan>(new TimeSpan(), new TimeSpan());
        }

        // método que modifica horário atendimento
        // -1 = hora invalida e 0 = sucesso
        public int set_horario_atendimento(int hora_abertura, int min_abertura, int hora_fecho, int min_fecho) {
            if (hora_abertura < 0 || hora_abertura >= 24 || min_abertura < 0 || min_abertura >= 60 || hora_fecho < 0 || hora_fecho >= 24 || min_fecho < 0 || min_fecho >= 60) return -1;
            if (hora_abertura == hora_fecho && min_abertura > min_fecho) return -1;
            MySqlCommand comm = new MySqlCommand("gerente_servico_atendimento",connection.get_connector());
            comm.CommandType = CommandType.StoredProcedure;
            comm.Parameters.Add("hora_a", MySqlDbType.Int16).Value = hora_abertura;
            comm.Parameters.Add("min_a", MySqlDbType.Int16).Value = min_abertura;
            comm.Parameters.Add("hora_f", MySqlDbType.Int16).Value = hora_fecho;
            comm.Parameters.Add("min_f", MySqlDbType.Int16).Value = min_fecho;
            comm.ExecuteNonQuery();
            return 0;
        }

    }
}
