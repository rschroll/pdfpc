/**
 * Spezialized Pdf View
 *
 * This file is part of pdfpc.
 *
 * Copyright (C) 2010-2011 Jakob Westhoff <jakob@westhoffswelt.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

namespace pdfpc {
    /**
     * View spezialized to work with Pdf renderers.
     *
     * This class is mainly needed to be decorated with pdf-link-interactions
     * signals.
     *
     * By default it does not implement any further functionality.
     */
    public class View.Pdf : View.Default {
        /**
         * Default constructor restricted to Pdf renderers as input parameter
         */
        public Pdf(Renderer.Pdf renderer, bool allow_black_on_end, bool clickable_links,
            PresentationController presentation_controller) {
            base(renderer);

            if (clickable_links)
                // Enable the PDFLink Behaviour by default on PDF Views
                this.associate_behaviour(new View.Behaviour.PdfLink());
        }

        /**
         * Create a new Pdf view directly from a file
         *
         * This is a convenience constructor which automatically create a full
         * metadata and rendering chain to be used with the pdf view. The given
         * width and height is used in conjunction with a scaler to maintain
         * aspect ration. The scale rectangle is provided in the scale_rect
         * argument.
         */
        public Pdf.from_metadata(Metadata.Pdf metadata, Metadata.Area area, bool allow_black_on_end,
            bool clickable_links, PresentationController presentation_controller) {
            Renderer.Pdf renderer = (area == Metadata.Area.NOTES) ?
                presentation_controller.notes_renderer : presentation_controller.slide_renderer;

            this(renderer, allow_black_on_end, clickable_links, presentation_controller);
        }

        /**
         * Return the currently used Pdf renderer
         */
        public new Renderer.Pdf get_renderer() {
            return this.renderer as Renderer.Pdf;
        }

        /**
         * Convert an arbitrary Poppler.Rectangle struct into a Gdk.Rectangle
         * struct taking into account the measurement differences between pdf
         * space and screen space.
         */
        public Gdk.Rectangle convert_poppler_rectangle_to_gdk_rectangle(
            Poppler.Rectangle poppler_rectangle) {
            Metadata.Pdf metadata = this.get_renderer().metadata as Metadata.Pdf;
            int width = this.get_allocated_width();
            int height = this.get_allocated_height();
            double page_width = metadata.get_page_width();
            double page_height = metadata.get_page_height();
            double scale = double.min(width / page_width, height / page_height);
            Gdk.Rectangle gdk_rectangle = Gdk.Rectangle();

            // We need the page dimensions for coordinate conversion between
            // pdf coordinates and screen coordinates
            gdk_rectangle.x = (int) Math.ceil(poppler_rectangle.x1 * scale +
                (width - page_width * scale) / 2);
            gdk_rectangle.width = (int) Math.floor((poppler_rectangle.x2 - poppler_rectangle.x1 ) *
                scale);

            // Gdk has its coordinate origin in the upper left, while Poppler
            // has its origin in the lower left.
            gdk_rectangle.y = (int) Math.ceil((page_height - poppler_rectangle.y2) * scale +
                (height - page_height * scale) / 2);
            gdk_rectangle.height = (int) Math.floor((poppler_rectangle.y2 - poppler_rectangle.y1) *
                scale);

            return gdk_rectangle;
        }
    }
}

