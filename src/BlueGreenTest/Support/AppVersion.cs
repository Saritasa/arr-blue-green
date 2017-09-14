namespace FormI9v2.Core.Infrastructure
{
    /// <summary>
    /// Contains info about app version.
    /// </summary>
    public class AppVersion
    {
        /// <summary>
        /// Short version. Contains major, minor, patch.
        /// </summary>
        public string FileVersion { get; set; }

        /// <summary>
        /// Long version. Contains Git branch and changeset.
        /// </summary>
        public string ProductVersion { get; set; }

        /// <summary>
        /// Deployment slot.
        /// </summary>
        public string Slot { get; set; }
    }
}
