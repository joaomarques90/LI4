using System;
using System.Collections.Generic;
using System.Text;

namespace SmartTicketApplication
{
    public class Ticket
    {
        public int id { get; set; }
        private int id_utilizador;
        public string nomeServico { get; set; }
        public string data{
            get;
            set;
        }
        public int nr_acesso { get; set; }
        public string estado { get; set; }
        public TimeSpan tempo_espera;
        public TimeSpan tempo_atendimento;
        public string observacoes;
        public int nr_atual;
        public string EstadoData { get; set; }
        public Ticket(int id, int id_utilizador, string servico_id, string data, int nr_acesso, string estado, TimeSpan tempo_espera, TimeSpan tempo_atendimento, string observacoes)
        {
            this.id = id;
            this.id_utilizador = id_utilizador;
            this.nomeServico = servico_id;
            this.data = data;
            this.nr_acesso = nr_acesso;
            this.estado = estado;
            this.tempo_espera = tempo_espera;
            this.tempo_atendimento = tempo_atendimento;
            this.observacoes = observacoes;
            
            EstadoData = this.estado + " Data - " + this.data;
        }

        // get´s e set´s

        static public Ticket stringToTicket(string input)
        {
            String[] resultado = input.Split('<');
            return new Ticket(int.Parse(resultado[0]), int.Parse(resultado[1]), resultado[2],resultado[3], int.Parse(resultado[4]), resultado[5], TimeSpan.Parse(resultado[6]), TimeSpan.Parse(resultado[7]),
                resultado[8]);
        }
        public int get_id_utilizador()
        {
            return this.id_utilizador;
        }

        public void set_id_utilizador(int id_utilizador)
        {
            this.id_utilizador = id_utilizador;
        }

      
      

    

      

        public TimeSpan get_tempo_espera()
        {
            return this.tempo_espera;
        }

        public void set_tempo_espera(TimeSpan tempo_espera)
        {
            this.tempo_espera = tempo_espera;
        }

        public TimeSpan get_tempo_atendimento()
        {
            return this.tempo_atendimento;
        }

        public void set_tempo_atendimento(TimeSpan tempo_atendimento)
        {
            this.tempo_atendimento = tempo_atendimento;
        }

        public string get_observacoes()
        {
            return this.observacoes;
        }

        public void set_observacoes(string observacoes)
        {
            this.observacoes = observacoes;
        }






    }
}
