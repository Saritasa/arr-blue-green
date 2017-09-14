using System;
using System.IO;
using System.Linq;
using System.Reflection;
using FormI9v2.Core.Infrastructure;

namespace FormI9v2.Core.Support
{
    public static class Util
    {
        /// <summary>
        /// Cached app version.
        /// </summary>
        private static readonly Lazy<AppVersion> version = new Lazy<AppVersion>(LoadAppVersion);

        /// <summary>
        /// Implementation of lazy-loading of app version.
        /// </summary>
        /// <returns></returns>
        private static AppVersion LoadAppVersion()
        {
            var executingAssembly = Assembly.GetExecutingAssembly();

            var result = new AppVersion
            {
                FileVersion = executingAssembly.GetName().Version.ToString(),
                Slot = new DirectoryInfo(AppDomain.CurrentDomain.BaseDirectory + "\\..").Name
            };

            var attribute = executingAssembly.GetCustomAttributes(typeof(AssemblyInformationalVersionAttribute), false).FirstOrDefault()
                as AssemblyInformationalVersionAttribute;

            if (attribute != null)
            {
                result.ProductVersion = attribute.InformationalVersion;
            }

            return result;
        }

        /// <summary>
        /// Returns info about app version.
        /// </summary>
        /// <returns></returns>
        public static AppVersion GetAppVersion()
        {
            return version.Value;
        }
    }
}