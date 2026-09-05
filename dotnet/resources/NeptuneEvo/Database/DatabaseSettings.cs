using LinqToDB.Configuration;
using System.Collections.Generic;
using System.Linq;

namespace NeptuneEvo.Database
{
    class DatabaseSettings : ILinqToDBSettings
    {
        public IEnumerable<IDataProviderSettings> DataProviders => Enumerable.Empty<IDataProviderSettings>();

        public string DefaultConfiguration => LinqToDB.ProviderName.MariaDB10MySqlConnector;
        public string DefaultDataProvider => LinqToDB.ProviderName.MariaDB10MySqlConnector;

        private readonly IConnectionStringSettings[] _connectionStrings;

        public DatabaseSettings(IConnectionStringSettings[] connectionStrings)
        {
            _connectionStrings = connectionStrings;
        }

        public IEnumerable<IConnectionStringSettings> ConnectionStrings => _connectionStrings;
    }
}
