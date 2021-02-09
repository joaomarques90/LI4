namespace SmartTicketApplication
{
    public class Funcionario : User
    {
        // variaveis de instancia
        public string NomeFuncionario { get; set; }
        public int id;


        // set´s e get´s
        public void set_id(int id)
        {
            this.id = id;
        }

        public int get_id()
        {
            return this.id;
        }

       

       

        // construtor
        public Funcionario(int nr, int id, string nome)
        {
            this.set_nr_telemovel(nr);
            this.id = id;
            this.NomeFuncionario = nome;
        }

        public static Funcionario stringToFuncionario(string input)
        {
            string[] resultado = input.Split('/');
            return new Funcionario(int.Parse(resultado[0]), int.Parse(resultado[1]), resultado[2]);
        }
    }

}