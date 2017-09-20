using System;
using System.Web.Http;

namespace BlueGreenTest.Controllers
{
    public class TestResponse
    {
        public string Scheme { get; set; }

        public string Host { get; set; }

        public int Port { get; set; }

        public string FinalUrl { get; set; }

        public string ServerVariables { get; set; }

        public string Headers { get; set; }
    }

    public class UrlController : ApiController
    {
        private const string ProductionHost = "example.com";

        [HttpGet, ActionName("arr")]
        public TestResponse TestArr()
        {
            var requestUri = Request.RequestUri;

            string scheme;
            string authority;

            var httpContext = System.Web.HttpContext.Current;
            var serverVariable = httpContext.Request.ServerVariables["HTTP_X_ARR_SSL"];

            // Production, behind ARR.
            if (serverVariable != null)
            {
                scheme = "https";
                authority = requestUri.Host;
            }
            else
            {
                scheme = requestUri.Scheme;
                authority = requestUri.Authority;
            }

            var url = $"{scheme}://{authority}{RequestContext.VirtualPathRoot}";
            string headerValue = null;

            if (Request.Headers.Contains("X-ARR-SSL"))
            {
                headerValue = string.Join(",", Request.Headers.GetValues("X-ARR-SSL"));
            }

            return new TestResponse
            {
                Scheme = requestUri.Scheme,
                Host = requestUri.Host,
                Port = requestUri.Port,
                FinalUrl = url,
                ServerVariables = $"HTTP_X_ARR_SSL={serverVariable}",
                Headers = $"X-ARR-SSL={headerValue}",
            };
        }

        [HttpGet, ActionName("general")]
        public TestResponse TestGeneral()
        {
            var requestUri = RequestContext.Url.Request.RequestUri;

            string scheme;
            string authority;

            // Production, behind load balancer.
            if (string.Compare(requestUri.Host, ProductionHost, StringComparison.OrdinalIgnoreCase) == 0)
            {
                scheme = "https";
                authority = requestUri.Host;
            }
            else
            {
                scheme = requestUri.Scheme;
                authority = requestUri.Authority;
            }

            var url = $"{scheme}://{authority}{RequestContext.VirtualPathRoot}";

            return new TestResponse { Scheme = requestUri.Scheme, Host = requestUri.Host, Port = requestUri.Port, FinalUrl = url };
        }
    }
}