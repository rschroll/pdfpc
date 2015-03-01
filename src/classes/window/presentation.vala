/**
 * Presentation window
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

namespace pdfpc.Window {
    /**
     * Window showing the currently active slide to be presented on a beamer
     */
    public class Presentation : Fullscreen, Controllable {
        /**
         * The registered PresentationController
         */
        public PresentationController presentation_controller { get; protected set; }

        /**
         * The only view is the main view.
         */
        public View.Pdf main_view {
            get {
                return this.view as View.Pdf;
            }
        }

        /**
         * View containing the slide to show
         */
        protected View.Base view;

        /**
         * Base constructor instantiating a new presentation window
         */
        public Presentation(Metadata.Pdf metadata, int screen_num,
            PresentationController presentation_controller, int width = -1, int height = -1) {
            base(screen_num, width, height);
            this.role = "presentation";

            this.destroy.connect((source) => presentation_controller.quit());

            this.presentation_controller = presentation_controller;

            if (width < 0) {
                width = this.screen_geometry.width;
            }

            if (height < 0) {
                height = this.screen_geometry.height;
            }

            this.view = new View.Pdf.from_metadata(metadata, Metadata.Area.CONTENT,
                Options.black_on_end, true, this.presentation_controller);
            this.add(this.view);

            this.add_events(Gdk.EventMask.KEY_PRESS_MASK);
            this.add_events(Gdk.EventMask.BUTTON_PRESS_MASK);
            this.add_events(Gdk.EventMask.SCROLL_MASK);

            this.key_press_event.connect(this.presentation_controller.key_press);
            this.button_press_event.connect(this.presentation_controller.button_press);
            this.scroll_event.connect(this.presentation_controller.scroll);

            this.presentation_controller.register_controllable(this);
        }

        /**
         * Set the presentation controller which is notified of keypresses and
         * other observed events
         */
        public void set_controller(PresentationController controller) {
            this.presentation_controller = controller;
        }

        /**
         * Update the display
         */
        public void update() {
            if (this.presentation_controller.faded_to_black) {
                this.view.fade_to_black();
                return;
            }
            if (this.presentation_controller.frozen)
                return;

            this.view.display(this.presentation_controller.current_slide_number, true);
        }

        /**
         * Set the cache observer for the Views on this window
         *
         * This method takes care of registering all Prerendering Views used by
         * this window correctly with the CacheStatus object to provide acurate
         * cache status measurements.
         */
        public void set_cache_observer(CacheStatus observer) {}
    }
}

