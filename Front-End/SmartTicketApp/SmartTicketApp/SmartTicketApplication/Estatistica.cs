namespace SmartTicketApplication
{
    public class Estatistica
    {
        private double tempo_medio_espera;
        private int congestao;

        public double get_tempo_medio_espera() {
            return tempo_medio_espera;
        }
        
        public int get_congestao() {
            return congestao;
        }

        public void set_tempo_medio_espera(double t)
        {
            this.tempo_medio_espera = t;
        }
        
        public void set_congestao(int c)
        {
            this.congestao = c;
        }

        public Estatistica(double t, int c) {
            tempo_medio_espera = t;
            congestao = c;
        }
        
        public string ToString() {
            return "Tempo Espera= " + this.get_tempo_medio_espera() + " " + "Congestao= " + this.get_congestao() + "\n";
        }
    }
}