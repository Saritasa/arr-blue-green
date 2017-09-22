using System.Web;
using System.Web.Http;

namespace BlueGreenTest.Controllers
{
    public class SessionController : ApiController
    {
        [HttpGet]
        public string Test()
        {
            HttpContext.Current.Session["TEST"] = 123;

            return "HELLO";
        }
    }
}