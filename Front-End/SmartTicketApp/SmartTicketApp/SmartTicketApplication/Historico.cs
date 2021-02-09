namespace SmartTicketApplication
{
    public class Historico
    {
        private double tempo_medio_espera;
        private int congestao_media;
        private double tempo_medio_atendimento;

        public double get_tempo_medio_espera() {
            return tempo_medio_espera;
        }
        
        public int get_congestao_media() {
            return congestao_media;
        }
        public double get_tempo_medio_atendimento()
        {
            return tempo_medio_atendimento;
        }
        public Historico(double t, int c,double a) {
            tempo_medio_espera = t;
            congestao_media = c;
            tempo_medio_atendimento = a;
        }
        
        public string ToString() {
            return "Tempo Espera= " + this.get_tempo_medio_espera() + " " + "Congestao= " + this.get_congestao_media() + "\n";
        }
    }
}