/**
 * Pdf renderer
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
     * Pdf slide renderer
     */
    public class Renderer.Pdf : Renderer.Base {
        /**
         * Signal emitted every time a precached slide has been created
         *
         * This signal should be emitted slide_count number of times during a
         * precaching cylce.
         */
        public signal void slide_prerendered(int i);

        /**
         * Signal emitted when the precaching cycle is complete
         */
        public signal void prerendering_completed();

        /**
         * The scaling factor needed to render the pdf page to the desired size.
         */
        protected double scaling_factor;

        /**
         * The area of the pdf which shall be displayed
         */
        protected Metadata.Area area;

        protected Cairo.RecordingSurface[] cache = null;

        protected bool prerendering = false;

        /**
         * Base constructor taking a pdf metadata object as well as the desired
         * render width and height as parameters.
         *
         * The pdf will always be rendered to fill up all available space. If
         * the proportions of the rendersize do not fit the proportions of the
         * pdf document the renderspace is filled up completely cutting of a
         * part of the pdf document.
         */
        public Pdf(Metadata.Pdf metadata, int width, int height, Metadata.Area area) {
            base(metadata, width, height);

            this.area = area;

            // Calculate the scaling factor needed.
            this.scaling_factor = Math.fmin(width / metadata.get_page_width(),
                height / metadata.get_page_height());
            //this.width = (int) metadata.get_page_width();
            //this.height = (int) metadata.get_page_height();
            double page_aspect = metadata.get_page_width() / metadata.get_page_height();
            if (page_aspect > (double) width / height)
                this.width = (int) (height * page_aspect);
            else
                this.height = (int) (width / page_aspect);

            if (!Options.disable_caching) {
                this.cache = new Cairo.RecordingSurface[metadata.get_slide_count()];
            }
        }

        /**
         * Render the given slide_number to a Cairo.Context and return it.
         *
         * If the requested slide is not available an
         * RenderError.SLIDE_DOES_NOT_EXIST error is thrown.
         */
        public override void render(Cairo.Context? context, int slide_number, int display_width,
            int display_height)
            throws Renderer.RenderError {
            var metadata = this.metadata as Metadata.Pdf;

            // Check if a valid page is requested, before locking anything.
            if (slide_number < 0 || slide_number >= metadata.get_slide_count()) {
                throw new Renderer.RenderError.SLIDE_DOES_NOT_EXIST(
                    "The requested slide '%i' does not exist.", slide_number);
            }
            if (this.cache == null) {
                if (context != null)
                    render_direct(context, slide_number, display_width, display_height);
                return;
            }

            Cairo.RecordingSurface record = this.cache[slide_number];
            if (record == null) {
                record = new Cairo.RecordingSurface(Cairo.Content.COLOR,
                    {0, 0, this.width, this.height});
                Cairo.Context record_context = new Cairo.Context(record);
                this.render_direct(record_context, slide_number, this.width, this.height);
                this.cache[slide_number] = record;
                this.slide_prerendered(slide_number);
            }
            if (context != null) {
                double scale = double.min(display_width / (double) this.width,
                    display_height / (double) this.height);
                context.scale(scale, scale);
                context.set_source_surface(record, 0, 0);
                context.paint();
            }
        }

        public Gdk.Pixbuf? render_pixbuf(int slide_number, int display_width, int display_height)
            throws Renderer.RenderError {
            Cairo.ImageSurface current_slide = new Cairo.ImageSurface(Cairo.Format.RGB24,
                display_width, display_height);
            Cairo.Context context = new Cairo.Context(current_slide);
            this.render(context, slide_number, display_width, display_height);
            return Gdk.pixbuf_get_from_surface(current_slide, 0, 0, display_width, display_height);
        }

        private void render_direct(Cairo.Context context, int slide_number, int display_width,
            int display_height) {
            Metadata.Pdf metadata = this.metadata as Metadata.Pdf;
            double scale = double.min(display_width / metadata.get_page_width(),
                display_height / metadata.get_page_height());
            Poppler.Page page = metadata.get_document().get_page(slide_number);
            
            // A lot of Pdfs have transparent backgrounds defined. We render
            // every page before a white background because of this.
            context.set_source_rgb(255, 255, 255);
            context.rectangle(0, 0, display_width, display_height);
            context.fill();

            context.scale(scale, scale);
            context.translate(-metadata.get_horizontal_offset(this.area),
                -metadata.get_vertical_offset(this.area));
            page.render(context);
        }

        public async void finish_prerender() {
            if (this.prerendering)
                return;
            this.prerendering = true;

            uint page_count = this.metadata.get_slide_count();
            for (int i = 0; i < page_count; i++) {
                Idle.add(this.finish_prerender.callback);
                yield;
                
                // We do not care about the result, as the
                // rendering function stores the rendered
                // pixmap in the cache if it is enabled. This
                // is exactly what we want.
                try {
                    this.render(null, i, 0, 0);
                } catch(Renderer.RenderError e) {
                    error("Could not render page '%i' while pre-rendering: %s", i, e.message);
                }
            }
            this.prerendering_completed();
        }
    }
}

