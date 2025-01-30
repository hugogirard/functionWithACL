using System.IO;
using System.Threading.Tasks;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace Contoso
{
    public class GetDocuments
    {
        private readonly ILogger<GetDocuments> _logger;

        public GetDocuments(ILogger<GetDocuments> logger)
        {
            _logger = logger;
        }

        [Function(nameof(GetDocuments))]
        [BlobOutput("doc/labs/hello-output.txt", Connection = "DatalakeStorage")]

        public async Task<string> Run([BlobTrigger("doc/result/{name}", Connection = "DatalakeStorage")] Stream stream, string name)
        {
            using var blobStreamReader = new StreamReader(stream);
            var content = await blobStreamReader.ReadToEndAsync();
            _logger.LogInformation($"C# Blob trigger function Processed blob\n Name: {name} \n Data: {content}");

            var output = $"{content.ToString()}{DateTime.UtcNow.ToString()}";

            return output;
        }
    }
}
