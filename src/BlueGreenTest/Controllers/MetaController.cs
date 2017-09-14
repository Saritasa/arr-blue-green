using FormI9v2.Core.Infrastructure;
using FormI9v2.Core.Support;
using System.Web.Http;

namespace BlueGreenTest.Controllers
{
    public class MetaController : ApiController
    {
        [HttpGet, ActionName("version")]
        public AppVersion Version()
        {
            return Util.GetAppVersion();
        }
    }
}