class ConversionsController < ApplicationController
  require 'prawn'
  require 'mini_magick'
  require 'zip'
  require 'shellwords'

  def new
    # No need for a model instance
  end

  def create
    if params[:file].present?
      uploaded_file = params[:file]
      file_extension = File.extname(uploaded_file.original_filename).downcase

      case file_extension
      when '.jpg', '.jpeg'
        output_pdf = convert_jpeg_to_pdf(uploaded_file)
        send_file output_pdf, filename: "converted.pdf", type: "application/pdf"
      when '.pdf'
        output_zip = convert_pdf_to_jpeg(uploaded_file)
        send_file output_zip, filename: "converted_jpegs.zip", type: "application/zip"
      else
        flash[:alert] = "Unsupported file type."
        redirect_to new_conversion_path
      end
    else
      flash[:alert] = "Please upload a file."
      redirect_to new_conversion_path
    end
  rescue StandardError => e
    Rails.logger.error "Conversion error: #{e.message}"
    flash[:alert] = "An error occurred during conversion."
    redirect_to new_conversion_path
  ensure
    # Clean up temporary files if necessary
  end

  private

  # Convert JPEG to PDF
  def convert_jpeg_to_pdf(uploaded_file)
    output_pdf = Rails.root.join('tmp', "converted_#{Time.now.to_i}.pdf")
    file_path = save_temp_file(uploaded_file)

    Prawn::Document.generate(output_pdf) do |pdf|
      pdf.image file_path, fit: [pdf.bounds.width, pdf.bounds.height], position: :center
    end

    File.delete(file_path) if File.exist?(file_path)
    output_pdf
  end

  # Convert PDF to JPEG
  def convert_pdf_to_jpeg(uploaded_file)
    output_dir = Rails.root.join('tmp', "pdf_to_jpeg_#{Time.now.to_i}")
    Dir.mkdir(output_dir) unless Dir.exist?(output_dir)

    file_path = save_temp_file(uploaded_file)

    system("pdftoppm -jpeg #{Shellwords.escape(file_path)} #{output_dir}/page")

    zipfile_name = Rails.root.join('tmp', "converted_jpegs_#{Time.now.to_i}.zip")
    entries = Dir.entries(output_dir) - %w[. ..]

    # Ensure Zip module is used correctly
    Zip::File.open(zipfile_name, create: true) do |zipfile|
      entries.each do |entry|
        zipfile.add(entry, File.join(output_dir, entry))
      end
    end

    # Clean up
    File.delete(file_path) if File.exist?(file_path)
    FileUtils.rm_rf(output_dir) if Dir.exist?(output_dir)

    zipfile_name
  end

  # Helper method to save the uploaded file to a temporary location
  def save_temp_file(uploaded_file)
    temp_file = Rails.root.join('tmp', uploaded_file.original_filename)
    File.open(temp_file, 'wb') do |file|
      file.write(uploaded_file.read)
    end
    temp_file
  end
end
